# Helper used by the unboxed path rendering (shadowed bobthefish functions
# in this directory). Closes whichever segment is currently open by drawing
# its rounded right cap, then clears the open-segment state so the next
# segment opens a fresh pill and __bobthefish_finish_segments doesn't
# paint a stray cap after trailing plain text. Plain, -S-shadowing like
# the other bobthefish segment helpers.

function __bobthefish_close_segment -S -d 'Close the currently open prompt segment and clear it'
    if [ -n "$__bobthefish_current_bg" ]
        set_color normal
        set_color $__bobthefish_current_bg
        echo -ns $right_black_arrow_glyph ' '
        set __bobthefish_current_bg ''
    end
    set_color normal
end