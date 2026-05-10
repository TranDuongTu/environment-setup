function ws --description "Launch or switch to a tmuxinator workspace (fzf picker)"
    # If session already exists, switch directly without prompting
    set -l existing (tmux list-sessions -F "#S" 2>/dev/null | grep -E "^workspace")
    if test -n "$existing"
        set -l target (echo $existing | tr ' ' '\n' | fzf \
            --prompt="Switch to > " \
            --height=~10 \
            --border=rounded \
            --header="Existing workspace sessions (Enter to switch, Esc to create new)")
        if test -n "$target"
            tmux switch-client -t $target
            return
        end
    end

    # Pick layout
    set -l layout (printf "workspace-big-screen\nworkspace" | fzf \
        --prompt="Layout > " \
        --height=~10 \
        --border=rounded \
        --header="workspace-big-screen: nvim 70% | agent 30% + btop  //  workspace: 3 windows")
    test -z "$layout"; and return

    # Pick repo — find git repos up to 3 levels deep in ~/projects/
    set -l repo (find ~/projects -maxdepth 3 -name ".git" -type d 2>/dev/null | sed 's|/.git$||' | sort | fzf \
        --prompt="Repo > " \
        --height=~20 \
        --border=rounded \
        --preview="ls {}" \
        --header="Select repository")
    test -z "$repo"; and return

    # Pick agent
    set -l agent (printf "opencode\nclaude\ncodex" | fzf \
        --prompt="Agent > " \
        --height=~10 \
        --border=rounded \
        --header="Select AI agent")
    test -z "$agent"; and return

    set -x WORKSPACE_REPO $repo
    set -x WORKSPACE_AGENT $agent
    # Propagate to tmux server env so panes in the new session see them
    if set -q TMUX
        tmux set-environment -g WORKSPACE_REPO $repo
        tmux set-environment -g WORKSPACE_AGENT $agent
    end
    tmuxinator start $layout
end
