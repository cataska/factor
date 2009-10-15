! Copyright (C) 2007, 2009 Chris Double, Doug Coleman, Eduardo
! Cavazos, Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: kernel kernel.private sequences sequences.private math
combinators macros math.order math.ranges quotations fry effects
memoize.private ;
IN: generalizations

<<

ALIAS: n*quot (n*quot)

: repeat ( n obj quot -- ) swapd times ; inline

>>

MACRO: nsequence ( n seq -- )
    [ [nsequence] ] keep
    '[ @ _ like ] ;

MACRO: narray ( n -- )
    '[ _ { } nsequence ] ;

MACRO: nsum ( n -- )
    1 - [ + ] n*quot ;

MACRO: firstn-unsafe ( n -- )
    [firstn] ;

MACRO: firstn ( n -- )
    dup zero? [ drop [ drop ] ] [
        [ 1 - swap bounds-check 2drop ]
        [ firstn-unsafe ]
        bi-curry '[ _ _ bi ]
    ] if ;

MACRO: npick ( n -- )
    1 - [ dup ] [ '[ _ dip swap ] ] repeat ;

MACRO: nover ( n -- )
    dup 1 + '[ _ npick ] n*quot ;

MACRO: ndup ( n -- )
    dup '[ _ npick ] n*quot ;

MACRO: dupn ( n -- )
    [ [ drop ] ]
    [ 1 - [ dup ] n*quot ] if-zero ;

MACRO: nrot ( n -- )
    1 - [ ] [ '[ _ dip swap ] ] repeat ;

MACRO: -nrot ( n -- )
    1 - [ ] [ '[ swap _ dip ] ] repeat ;

MACRO: set-firstn-unsafe ( n -- )
    [ 1 + ]
    [ iota [ '[ _ rot [ set-nth-unsafe ] keep ] ] map ] bi
    '[ _ -nrot _ spread drop ] ;

MACRO: set-firstn ( n -- )
    dup zero? [ drop [ drop ] ] [
        [ 1 - swap bounds-check 2drop ]
        [ set-firstn-unsafe ]
        bi-curry '[ _ _ bi ]
    ] if ;

MACRO: ndrop ( n -- )
    [ drop ] n*quot ;

MACRO: nnip ( n -- )
    '[ [ _ ndrop ] dip ] ;

MACRO: ntuck ( n -- )
    2 + '[ dup _ -nrot ] ;

MACRO: ndip ( n -- )
    [ [ dip ] curry ] n*quot [ call ] compose ;

MACRO: nkeep ( n -- )
    dup '[ [ _ ndup ] dip _ ndip ] ;

MACRO: ncurry ( n -- )
    [ curry ] n*quot ;

MACRO: nwith ( n -- )
    [ with ] n*quot ;

MACRO: nbi ( n -- )
    '[ [ _ nkeep ] dip call ] ;

MACRO: ncleave ( quots n -- )
    [ '[ _ '[ _ _ nkeep ] ] map [ ] join ] [ '[ _ ndrop ] ] bi
    compose ;

MACRO: nspread ( quots n -- )
    over empty? [ 2drop [ ] ] [
        [ [ but-last ] dip ]
        [ [ last ] dip ] 2bi
        swap
        '[ [ _ _ nspread ] _ ndip @ ]
    ] if ;

MACRO: spread* ( n -- )
    [ [ ] ] [
        1 swap [a,b) [ '[ [ [ _ ndip ] curry ] dip compose ] ] map [ ] concat-as
        [ call ] compose
    ] if-zero ;

MACRO: cleave* ( n -- )
    [ [ ] ]
    [ 1 - [ [ [ keep ] curry ] dip compose ] n*quot [ call ] compose ] 
    if-zero ;

MACRO: napply ( n -- )
    [ [ drop ] ] dip [ '[ tuck _ 2dip call ] ] times ;

: apply-curry ( ...a quot n -- )
    [ [curry] ] dip napply ; inline

: cleave-curry ( a ...quot n -- )
    [ [curry] ] swap [ napply ] [ cleave* ] bi ; inline

: spread-curry ( ...a ...quot n -- )
    [ [curry] ] swap [ napply ] [ spread* ] bi ; inline

MACRO: mnswap ( m n -- )
    1 + '[ _ -nrot ] swap '[ _ _ napply ] ;

MACRO: nweave ( n -- )
    [ dup iota <reversed> [ '[ _ _ mnswap ] ] with map ] keep
    '[ _ _ ncleave ] ;

MACRO: nbi-curry ( n -- )
    [ bi-curry ] n*quot ;

: nappend-as ( n exemplar -- seq )
    [ narray concat ] dip like ; inline

: nappend ( n -- seq ) narray concat ; inline

MACRO: nspin ( n -- )
    [ [ ] ] swap [ swap [ ] curry compose ] n*quot [ call ] 3append ;

MACRO: nmin-length ( n -- )
    dup 1 - [ min ] n*quot
    '[ [ length ] _ napply @ ] ;

: nnth-unsafe ( n ...seq n -- )
    [ nth-unsafe ] swap [ apply-curry ] [ cleave* ] bi ; inline
MACRO: nset-nth-unsafe ( n -- )
    [ [ drop ] ]
    [ '[ [ set-nth-unsafe ] _ [ apply-curry ] [ cleave-curry ] [ spread* ] tri ] ]
    if-zero ;

: (neach) ( ...seq quot n -- len quot' )
    dup dup dup
    '[ [ _ nmin-length ] _ nkeep [ _ nnth-unsafe ] _ ncurry ] dip compose ; inline

: neach ( ...seq quot n -- )
    (neach) each-integer ; inline

: nmap-as ( ...seq quot exemplar n -- result )
    '[ _ (neach) ] dip map-integers ; inline

: nmap ( ...seq quot n -- result )
    dup '[ [ _ npick ] dip swap ] dip nmap-as ; inline

MACRO: nnew-sequence ( n -- )
    [ [ drop ] ]
    [ dup '[ [ new-sequence ] _ apply-curry _ cleave* ] ] if-zero ;

: nnew-like ( len ...exemplar quot n -- result... )
    dup dup dup dup '[
        _ nover
        [ [ _ nnew-sequence ] dip call ]
        _ ndip [ like ]
        _ apply-curry
        _ spread*
    ] call ; inline

MACRO: (ncollect) ( n -- )
    dup dup 1 +
    '[ [ [ keep ] _ ndip _ nset-nth-unsafe ] _ ncurry ] ;

: ncollect ( len quot ...into n -- )
    (ncollect) each-integer ; inline

: nmap-integers ( len quot ...exemplar n -- result... )
    dup dup dup
    '[ [ over ] _ ndip [ [ _ ncollect ] _ nkeep ] _ nnew-like ] call ; inline

: mnmap-as ( m*seq quot n*exemplar m n -- result*n )
    dup '[ [ _ (neach) ] _ ndip _ nmap-integers ] call ; inline

: mnmap ( m*seq quot m n -- result*n )
    2dup '[ [ _ npick ] dip swap _ dupn ] 2dip mnmap-as ; inline

