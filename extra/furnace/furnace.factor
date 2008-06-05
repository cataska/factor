! Copyright (C) 2003, 2008 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays kernel combinators assocs
continuations namespaces sequences splitting words
vocabs.loader classes
fry urls multiline
xml
xml.data
xml.entities
xml.writer
xml.utilities
html.components
html.elements
html.templates
html.templates.chloe
html.templates.chloe.syntax
http
http.server
http.server.redirection
http.server.responses
qualified ;
QUALIFIED-WITH: assocs a
IN: furnace

: nested-responders ( -- seq )
    responder-nesting get a:values ;

: each-responder ( quot -- )
   nested-responders swap each ; inline

: base-path ( string -- pair )
    dup responder-nesting get
    [ second class word-name = ] with find nip
    [ first ] [ "No such responder: " swap append throw ] ?if ;

: resolve-base-path ( string -- string' )
    "$" ?head [
        [
            "/" split1 [ base-path [  "/" % % ] each "/" % ] dip %
        ] "" make
    ] when ;

: vocab-path ( vocab -- path )
    dup vocab-dir vocab-append-path ;

: resolve-template-path ( pair -- path )
    [
        first2 [ word-vocabulary vocab-path % ] [ "/" % % ] bi*
    ] "" make ;

GENERIC: modify-query ( query responder -- query' )

M: object modify-query drop ;

: adjust-url ( url -- url' )
    clone
        [ [ modify-query ] each-responder ] change-query
        [ resolve-base-path ] change-path
    relative-to-request ;

: <redirect> ( url -- response )
    adjust-url request get method>> {
        { "GET" [ <temporary-redirect> ] }
        { "HEAD" [ <temporary-redirect> ] }
        { "POST" [ <permanent-redirect> ] }
    } case ;

GENERIC: modify-form ( responder -- )

M: object modify-form drop ;

: request-params ( request -- assoc )
    dup method>> {
        { "GET" [ url>> query>> ] }
        { "HEAD" [ url>> query>> ] }
        { "POST" [
            post-data>>
            dup content-type>> "application/x-www-form-urlencoded" =
            [ content>> ] [ drop f ] if
        ] }
    } case ;

SYMBOL: exit-continuation

: exit-with exit-continuation get continue-with ;

: with-exit-continuation ( quot -- )
    '[ exit-continuation set @ ] callcc1 exit-continuation off ;

! Chloe tags
: parse-query-attr ( string -- assoc )
    dup empty?
    [ drop f ] [ "," split [ dup value ] H{ } map>assoc ] if ;

CHLOE: atom
    [ "title" required-attr ]
    [ "href" required-attr ]
    [ "query" optional-attr parse-query-attr ] tri
    <url>
        swap >>query
        swap >>path
    adjust-url relative-to-request
    add-atom-feed ;

CHLOE: write-atom drop write-atom-feeds ;

GENERIC: link-attr ( tag responder -- )

M: object link-attr 2drop ;

: link-attrs ( tag -- )
    '[ , _ link-attr ] each-responder ;

: a-start-tag ( tag -- )
    [
        <a
            dup link-attrs
            dup "value" optional-attr [ value f ] [
                [ "href" required-attr ]
                [ "query" optional-attr parse-query-attr ]
                bi
            ] ?if
            <url>
                swap >>query
                swap >>path
            adjust-url relative-to-request =href
        a>
    ] with-scope ;

CHLOE: a
    [ a-start-tag ]
    [ process-tag-children ]
    [ drop </a> ]
    tri ;

: hidden-form-field ( value name -- )
    over [
        <input
            "hidden" =type
            =name
            object>string =value
        input/>
    ] [ 2drop ] if ;

: form-nesting-key "factorformnesting" ;

: form-magic ( tag -- )
    [ modify-form ] each-responder
    nested-values get " " join f like form-nesting-key hidden-form-field
    "for" optional-attr [ hidden render ] when* ;

: form-start-tag ( tag -- )
    [
        [
            <form
                "POST" =method
                [ link-attrs ]
                [ "action" required-attr resolve-base-path =action ]
                [ tag-attrs non-chloe-attrs-only print-attrs ]
                tri
            form>
        ]
        [ form-magic ] bi
    ] with-scope ;

CHLOE: form
    [ form-start-tag ]
    [ process-tag-children ]
    [ drop </form> ]
    tri ;

STRING: button-tag-markup
<t:form class="inline" xmlns:t="http://factorcode.org/chloe/1.0">
    <button type="submit"></button>
</t:form>
;

: add-tag-attrs ( attrs tag -- )
    tag-attrs swap update ;

CHLOE: button
    button-tag-markup string>xml delegate
    {
        [ [ tag-attrs chloe-attrs-only ] dip add-tag-attrs ]
        [ [ tag-attrs non-chloe-attrs-only ] dip "button" tag-named add-tag-attrs ]
        [ [ children>string 1array ] dip "button" tag-named set-tag-children ]
        [ nip ]
    } 2cleave process-chloe-tag ;
