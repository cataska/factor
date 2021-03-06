! Copyright (C) 2006, 2009 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors continuations kernel models namespaces arrays
fry prettyprint ui ui.commands ui.gadgets ui.gadgets.labeled assocs
ui.gadgets.tracks ui.gadgets.buttons ui.gadgets.panes
ui.gadgets.status-bar ui.gadgets.scrollers ui.gadgets.borders
ui.gadgets.tables ui.gestures sequences inspector
models.arrow fonts ;
QUALIFIED-WITH: ui.tools.inspector i
IN: ui.tools.traceback

TUPLE: stack-entry object string ;

: <stack-entry> ( object -- stack-entry )
    dup unparse-short stack-entry boa ;

SINGLETON: stack-entry-renderer

M: stack-entry-renderer row-columns drop string>> 1array ;

M: stack-entry-renderer row-value drop object>> ;

: <stack-table> ( model -- table )
    [ [ <stack-entry> ] map ] <arrow> stack-entry-renderer <table>
        10 >>min-rows
        10 >>max-rows
        40 >>min-cols
        40 >>max-cols
        monospace-font >>font
        [ i:inspector ] >>action
        t >>single-click? ;

: <stack-display> ( model quot title -- gadget )
    [ '[ dup _ when ] <arrow> <stack-table> <scroller> ] dip
    <labeled-gadget> ;

: <callstack-display> ( model -- gadget )
    [ [ call>> callstack. ] when* ]
    <pane-control> t >>scrolls? <scroller>
    "Call stack" <labeled-gadget> ;

: <datastack-display> ( model -- gadget )
    [ data>> ] "Data stack" <stack-display> ;

: <retainstack-display> ( model -- gadget )
    [ retain>> ] "Retain stack" <stack-display> ;

TUPLE: traceback-gadget < track ;

: <traceback-gadget> ( model -- gadget )
    [
        vertical traceback-gadget new-track
        { 3 3 } >>gap
    ] dip
    [ >>model ]
    [
        [ vertical <track> { 3 3 } >>gap ] dip
        [
            [ horizontal <track> { 3 3 } >>gap ] dip
            [ <datastack-display> 1/2 track-add ]
            [ <retainstack-display> 1/2 track-add ] bi
            1/3 track-add
        ]
        [ <callstack-display> 2/3 track-add ] bi
        { 3 3 } <filled-border> 1 track-add
    ] bi
    add-toolbar ;

: variables ( traceback -- )
    model>> [ dup [ name>> vars-in-scope ] when ] <arrow> i:inspect-model ;

: traceback-window ( continuation -- )
    <model> <traceback-gadget> "Traceback" open-status-window ;

: inspect-continuation ( traceback -- )
    control-value i:inspector ;

traceback-gadget "toolbar" f {
    { T{ key-down f f "v" } variables }
    { T{ key-down f f "n" } inspect-continuation }
} define-command-map