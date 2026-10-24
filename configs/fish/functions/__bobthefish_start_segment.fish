# Shadowed copy of bobthefish's __bobthefish_start_segment.
# ONLY DIFFERENCE vs upstream: a fresh segment (no previous block open)
# opens with a rounded left cap instead of a bare space, so stateful
# segments (git branch, status flags, ...) render as pills.
# See the header of __bobthefish_glyphs.fish for why we shadow.

function __bobthefish_start_segment -S -d 'Start a prompt segment'
    set -l bg $argv[1]
    set -e argv[1]
    set -l fg $argv[1]
    set -e argv[1]

    set_color normal # clear out anything bold or underline...
    set_color -b $bg $fg $argv

    switch "$__bobthefish_current_bg"
        case ''
            # No previous block: open a fresh one with a rounded left cap
            if [ -n "$bg" ]
                set_color normal
                set_color $bg
                echo -ns $left_black_arrow_glyph
                set_color -b $bg $fg $argv
                echo -n ' '
            else
                # No colors requested at all: behave like upstream
                echo -n ' '
            end
        case "$bg"
            # If the background is already the same color, draw a separator
            echo -ns $right_arrow_glyph ' '
        case '*'
            # otherwise, draw the end of the previous segment and the start of the next
            set_color $__bobthefish_current_bg
            echo -ns $right_black_arrow_glyph ' '
            set_color $fg $argv
    end

    set __bobthefish_current_bg $bg
end
