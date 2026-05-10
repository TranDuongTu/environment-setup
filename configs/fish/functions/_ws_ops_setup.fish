function _ws_ops_setup --description "Internal: build ops pane layout (btop top, k9s | agent bottom)"
    set -l folder (string trim -- "$WORKSPACE_FOLDER")
    set -l agent (string trim -- "$WORKSPACE_AGENT")
    test -z "$folder"; and set folder $HOME
    test -z "$agent"; and set agent "opencode"

    set -l win (tmux display-message -p "#{session_name}:#{window_index}")

    # Pane 1: bottom half — k9s
    tmux split-window -v -l '50%' -t "$win.0" -c "$folder" "k9s"
    tmux select-pane -t "$win.1" -T "ops-k9s"

    # Pane 2: split bottom horizontally — agent on the right
    tmux split-window -h -l '50%' -t "$win.1" -c "$folder" $agent
    tmux select-pane -t "$win.2" -T "ops-$agent"

    # Pane 0: btop — focus and replace this fish process
    tmux select-pane -t "$win.0" -T "ops-btop"
    exec btop
end
