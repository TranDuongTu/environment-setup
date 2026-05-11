function ws --description "Launch or switch to a tmuxinator workspace (fzf picker)"
    # If session already exists, offer to switch directly (Esc to create new)
    set -l existing (tmux list-sessions -F "#S" 2>/dev/null | grep -E "^(dev-|ops)")
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
    set -l layout (printf "dev\ndev-lite\nops" | fzf \
        --prompt="Layout > " \
        --height=~10 \
        --border=rounded \
        --header="dev: nvim 70 | agent 30 + btop  //  dev-lite: nvim | agent  //  ops: btop / k9s | agent")
    test -z "$layout"; and return

    # Agent picker (shared)
    set -l agent_choices "opencode\nclaude\ncodex"

    if test "$layout" = "ops"
        # ops: pick any project folder
        set -l folder (find ~/projects -maxdepth 3 -name ".git" -type d 2>/dev/null | sed 's|/.git$||' | sort | fzf \
            --prompt="Folder > " \
            --height=~20 \
            --border=rounded \
            --preview="ls {}" \
            --header="Select folder for ops")
        test -z "$folder"; and return

        set -l agent (printf $agent_choices | fzf \
            --prompt="Agent > " \
            --height=~10 \
            --border=rounded \
            --header="Select AI agent")
        test -z "$agent"; and return

        set -l session_name (_ws_unique_session "ops")
        test -z "$session_name"; and return

        set -x WORKSPACE_FOLDER $folder
        set -x WORKSPACE_AGENT $agent
        if set -q TMUX
            tmux set-environment -g WORKSPACE_FOLDER $folder
            tmux set-environment -g WORKSPACE_AGENT $agent
        end
        tmuxinator start ops --name=$session_name
        return
    end

    # dev / dev-lite: pick repo + agent
    set -l repo (find ~/projects -maxdepth 3 -name ".git" -type d 2>/dev/null | sed 's|/.git$||' | sort | fzf \
        --prompt="Repo > " \
        --height=~20 \
        --border=rounded \
        --preview="ls {}" \
        --header="Select repository")
    test -z "$repo"; and return

    set -l agent (printf $agent_choices | fzf \
        --prompt="Agent > " \
        --height=~10 \
        --border=rounded \
        --header="Select AI agent")
    test -z "$agent"; and return

    set -l repo_name (basename $repo)
    set -l base_name "$layout-$repo_name-$agent"
    set -l session_name (_ws_unique_session $base_name)
    test -z "$session_name"; and return

    set -x WORKSPACE_REPO $repo
    set -x WORKSPACE_REPO_NAME $repo_name
    set -x WORKSPACE_AGENT $agent
    if set -q TMUX
        tmux set-environment -g WORKSPACE_REPO $repo
        tmux set-environment -g WORKSPACE_REPO_NAME $repo_name
        tmux set-environment -g WORKSPACE_AGENT $agent
    end
    tmuxinator start $layout --name=$session_name
end
