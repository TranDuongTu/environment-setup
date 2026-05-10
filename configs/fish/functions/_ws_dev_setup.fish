function _ws_dev_setup --description "Internal: build dev pane layout (nvim 70 / agent 30, btop bottom)"
    set -l repo (string trim -- "$WORKSPACE_REPO")
    set -l repo_name (string trim -- "$WORKSPACE_REPO_NAME")
    set -l agent (string trim -- "$WORKSPACE_AGENT")
    test -z "$repo"; and set repo $HOME
    test -z "$repo_name"; and set repo_name (basename "$repo")
    test -z "$agent"; and set agent "opencode"

    set -l win (tmux display-message -p "#{session_name}:#{window_index}")
    set -l win_h (tmux display-message -p -t "$win.0" '#{window_height}')

    # btop refuses to start under ~24 rows.
    set -l btop_h (math "round($win_h * 0.2)")
    test "$btop_h" -lt 24; and set btop_h 24

    # Pane 1: btop along the bottom
    tmux split-window -v -l "$btop_h" -t "$win.0" -c "$repo" "btop"
    tmux select-pane -t "$win.1" -T "dev-btop"
    tmux set-option -p -t "$win.1" remain-on-exit on

    # Pane 2: agent on the right of the top area (30%)
    tmux split-window -h -l '30%' -t "$win.0" -c "$repo" $agent
    tmux select-pane -t "$win.2" -T "dev-$agent"
    tmux set-option -p -t "$win.2" remain-on-exit on

    # Pane 0: nvim — focus and replace this fish process
    tmux select-pane -t "$win.0" -T "dev-$repo_name"
    tmux set-option -p -t "$win.0" remain-on-exit on
    exec nvim .
end
