function _ws_big_setup --description "Internal: build workspace-big-screen pane layout"
    set -l repo (string trim -- "$WORKSPACE_REPO")
    set -l agent (string trim -- "$WORKSPACE_AGENT")
    test -z "$repo"; and set repo $HOME
    test -z "$agent"; and set agent "opencode"

    set -l win (tmux display-message -p "#{session_name}:#{window_index}")

    # Pane 1: btop — horizontal split, bottom 20%, full width
    tmux split-window -v -l '20%' -t "$win.0" -c "$repo" "btop"

    # Pane 2: agent — vertical split of top area, right 30%
    tmux split-window -h -l '30%' -t "$win.0" -c "$repo" $agent

    # Pane 0: nvim — focus and replace this fish process
    tmux select-pane -t "$win.0"
    exec nvim .
end
