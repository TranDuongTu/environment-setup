function _ws_dev_lite_setup --description "Internal: build dev-lite pane layout (nvim 50 / agent 50)"
    set -l repo (string trim -- "$WORKSPACE_REPO")
    set -l repo_name (string trim -- "$WORKSPACE_REPO_NAME")
    set -l agent (string trim -- "$WORKSPACE_AGENT")
    test -z "$repo"; and set repo $HOME
    test -z "$repo_name"; and set repo_name (basename "$repo")
    test -z "$agent"; and set agent "opencode"

    set -l win (tmux display-message -p "#{session_name}:#{window_index}")

    # Pane 1: agent on the right (50%)
    tmux split-window -h -l '50%' -t "$win.0" -c "$repo" $agent
    tmux select-pane -t "$win.1" -T "dev-lite-$agent"

    # Pane 0: nvim — focus and replace this fish process
    tmux select-pane -t "$win.0" -T "dev-lite-$repo_name"
    exec nvim .
end
