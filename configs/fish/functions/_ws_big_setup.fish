function _ws_big_setup --description "Internal: build workspace-big-screen pane layout"
    set -l repo (string trim -- "$WORKSPACE_REPO")
    set -l agent (string trim -- "$WORKSPACE_AGENT")
    test -z "$repo"; and set repo $HOME
    test -z "$agent"; and set agent "opencode"

    set -l win (tmux display-message -p "#{session_name}:#{window_index}")
    set -l win_h (tmux display-message -p -t "$win.0" '#{window_height}')

    # Pane 1: btop — horizontal split, bottom is max(24 rows, 20% of window)
    # btop refuses to start under ~24 rows.
    set -l btop_h (math "round($win_h * 0.2)")
    test "$btop_h" -lt 24; and set btop_h 24
    tmux split-window -v -l "$btop_h" -t "$win.0" -c "$repo" "btop"

    # Pane 2: agent — vertical split of top area, right 30%
    tmux split-window -h -l '30%' -t "$win.0" -c "$repo" $agent

    # Pane 0: nvim — focus and replace this fish process
    tmux select-pane -t "$win.0"
    exec nvim .
end
