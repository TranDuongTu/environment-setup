function _ws_ops_setup --description "Internal: build ops pane layout (btop top, k9s | agent bottom)"
    set -l folder (string trim -- "$WORKSPACE_FOLDER")
    set -l agent (string trim -- "$WORKSPACE_AGENT")
    test -z "$folder"; and set folder $HOME
    test -z "$agent"; and set agent "opencode"

    set -l agent_cmd $agent
    test "$agent" = "claude"; and set agent_cmd "claude --dangerously-skip-permissions"
    test "$agent" = "opencode"; and set agent_cmd "env EDITOR=nvim opencode"

    set -l win (tmux display-message -p "#{session_name}:#{window_index}")
    set -l btop_pane (tmux display-message -p -t "$win.0" '#{pane_id}')

    # bottom half — k9s
    set -l k9s_pane (tmux split-window -v -l '50%' -t "$btop_pane" -c "$folder" -P -F '#{pane_id}' "k9s")
    tmux set-option -p -t "$k9s_pane" @role "ops-k9s"
    tmux select-pane -t "$k9s_pane" -T "ops-k9s"

    # split bottom horizontally — agent on the right
    set -l agent_pane (tmux split-window -h -l '50%' -t "$k9s_pane" -c "$folder" -P -F '#{pane_id}' $agent_cmd)
    tmux set-option -p -t "$agent_pane" @role "ops-$agent"
    tmux select-pane -t "$agent_pane" -T "ops-$agent"

    # btop — focus and replace this fish process
    tmux set-option -p -t "$btop_pane" @role "ops-btop"
    tmux select-pane -t "$btop_pane" -T "ops-btop"
    exec btop
end
