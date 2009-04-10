! Copyright (C) 2009 Wen-Chun Lin.
! See http://factorcode.org/license.txt for BSD license.
USING: kernel io sequences math math.ranges namespaces arrays 
prettyprint ;

IN: diamond

SYMBOL: mid
SYMBOL: height

: >mid ( max -- ) 2 /mod drop 1+ mid set ;

: mid> ( -- mid ) mid get ;

: >height ( height -- ) height set ;

: height> ( -- height ) height get ;

: print-spaces ( n -- )
    [ " " write ] times ;

: print-row ( start end -- )
    [a,b] >array [ pprint ] each "\n" write ;

: spaces ( row -- )
    mid> swap - 1- abs print-spaces ;

: numbers ( row -- start end )
    height> mid> [ + ] keep rot - 1- abs 2 * - 1- mid> swap ;

: row ( row -- )
    numbers print-row ;

: result ( row -- ) [ spaces ] [ row ] bi ;

: (diamond) ( -- )
     0 height> 1- [a,b] >array [ result ] each ;

: diamond ( height -- )
    [ >mid ] [ >height ] bi (diamond) ;