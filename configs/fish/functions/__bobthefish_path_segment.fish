# Shadowed copy of bobthefish's __bobthefish_path_segment.
# DIFFERENCE vs upstream: the path renders as plain, unboxed text (colored
# fg only, using fish's $fish_color_cwd / $fish_color_cwd_root) instead of a
# background block; only stateful segments (git, status, ...) wear blocks.
# It also closes any open segment first, since text segments don't trigger
# the block-transition logic of __bobthefish_start_segment.
# See the header of __bobthefish_glyphs.fish for why we shadow.

function __bobthefish_path_segment -S -a segment_dir -a path_type -d 'Display a shortened form of a directory'
    set -l segment_color $fish_color_cwd
    if not [ -w "$segment_dir" ]
        set segment_color $fish_color_cwd_root
    end

    __bobthefish_close_segment
    set_color $segment_color

    set -l directory
    set -l parent

    switch "$segment_dir"
        case /
            set directory /
        case "$HOME"
            set directory '~'
        case '*'
            set parent (__bobthefish_pretty_parent "$segment_dir")
            set directory (__bobthefish_basename "$segment_dir")
    end

    [ "$theme_show_project_parent" != no -o "$path_type" != project ]
    and echo -n $parent

    echo -ns $directory

    # Plain text: close our colors; the next segment (or the end of the
    # prompt) takes it from here
    set_color normal
    echo -n ' '
end
