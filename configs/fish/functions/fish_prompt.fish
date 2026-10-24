# fish_prompt — bobthefish with the paint layer owned by this repo:
#
#   ~ (path as plain unboxed text) ~ (git branch as rounded pill) ~ ...
#
# WHY THIS FILE EXISTS: bobthefish defines ALL of its helper functions
# (start_segment, path_segment, prompt_git, ...) inside the single
# fish_prompt.fish sourced by autoload — the moment the theme evaluates,
# its in-memory definitions beat any user-function shadowing of those
# names. So this user-dir fish_prompt (which always autoloads first) runs
# one guarded loader: source the upstream file, then re-source the repo's
# override copies on top, then run the upstream body verbatim.
#
# Override copies live next to this file; each documents its diff vs
# upstream at the top:
#
#   __bobthefish_glyphs.fish        rounded caps instead of arrows
#   __bobthefish_start_segment.fish pills open with a rounded left cap
#   __bobthefish_close_segment.fish close a pill before unboxed text
#   __bobthefish_path_segment.fish  path text (no background block)
#   __bobthefish_prompt_git.fish    repo-relative sub-path as text

function fish_prompt -d 'bobthefish, a fish theme optimized for awesome'
    # Save the last status for later (do this before anything else)
    set -l last_status $status

    # Use a simple prompt on dumb terminals.
    if [ "$TERM" = dumb ]
        echo '> '
        return
    end

    # Load upstream once, then the repo overrides (final in-memory defs win)
    if not set -q __bobthefish_user_prompt_loaded
        if not set -q OMF_PATH
            set -q XDG_DATA_HOME
              and set -gx OMF_PATH "$XDG_DATA_HOME/omf"
              or set -gx OMF_PATH "$HOME/.local/share/omf"
        end
        source $OMF_PATH/themes/bobthefish/functions/fish_prompt.fish
        source $__fish_config_dir/functions/__bobthefish_glyphs.fish
        source $__fish_config_dir/functions/__bobthefish_start_segment.fish
        source $__fish_config_dir/functions/__bobthefish_close_segment.fish
        source $__fish_config_dir/functions/__bobthefish_path_segment.fish
        source $__fish_config_dir/functions/__bobthefish_prompt_git.fish
        set -g __bobthefish_user_prompt_loaded yes
    end

    __bobthefish_glyphs
    __bobthefish_colors $theme_color_scheme

    type -q bobthefish_colors
    and bobthefish_colors

    # Start each line with a blank slate
    set -l __bobthefish_current_bg

    set -l real_pwd (__bobthefish_pwd)

    # Status flags and input mode
    __bobthefish_prompt_status $last_status

    # User / hostname info
    __bobthefish_prompt_user

    # Screen
    __bobthefish_prompt_screen

    # Containers and VMs
    __bobthefish_prompt_vagrant
    __bobthefish_prompt_docker
    __bobthefish_prompt_k8s_context

    # Cloud Tools
    __bobthefish_prompt_aws_vault_profile

    # Virtual environments
    __bobthefish_prompt_nix
    __bobthefish_prompt_desk
    __bobthefish_prompt_rubies
    __bobthefish_prompt_golang $real_pwd
    __bobthefish_prompt_virtualfish
    __bobthefish_prompt_virtualgo
    __bobthefish_prompt_node

    # VCS
    set -l git_root_dir (__bobthefish_git_project_dir $real_pwd)
    set -l hg_root_dir (__bobthefish_hg_project_dir $real_pwd)
    set -l fossil_root_dir (__bobthefish_fossil_project_dir $real_pwd)

    # only show the closest parent
    switch (__bobthefish_closest_parent "$git_root_dir" "$hg_root_dir" "$fossil_root_dir")
        case ''
            __bobthefish_prompt_dir $real_pwd
        case "$git_root_dir"
            __bobthefish_prompt_git $git_root_dir $real_pwd
        case "$hg_root_dir"
            __bobthefish_prompt_hg $hg_root_dir $real_pwd
        case "$fossil_root_dir"
            __bobthefish_prompt_fossil $fossil_root_dir $real_pwd
    end

    __bobthefish_finish_segments
end