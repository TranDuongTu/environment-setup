function _ws_dev_setup --description "Internal: build dev pane layout (nvim 70 / agent 30, btop bottom)"
    set -l repo (string trim -- "$WORKSPACE_REPO")
    set -l repo_name (string trim -- "$WORKSPACE_REPO_NAME")
    set -l agent (string trim -- "$WORKSPACE_AGENT")
    test -z "$repo"; and set repo $HOME
    test -z "$repo_name"; and set repo_name (basename "$repo")
    test -z "$agent"; and set agent "opencode"

    set -l agent_cmd $agent
    test "$agent" = "claude"; and set agent_cmd "claude --dangerously-skip-permissions"
    test "$agent" = "opencode"; and set agent_cmd "env EDITOR=nvim opencode"

    set -l win (tmux display-message -p "#{session_name}:#{window_index}")
    set -l nvim_pane (tmux display-message -p -t "$win.0" '#{pane_id}')
    set -l win_h (tmux display-message -p -t "$nvim_pane" '#{window_height}')

    # btop refuses to start under ~24 rows.
    set -l btop_h (math "round($win_h * 0.2)")
    test "$btop_h" -lt 24; and set btop_h 24

    # btop along the bottom
    set -l btop_pane (tmux split-window -v -l "$btop_h" -t "$nvim_pane" -c "$repo" -P -F '#{pane_id}' "btop")
    tmux set-option -p -t "$btop_pane" @role "dev-btop"
    tmux select-pane -t "$btop_pane" -T "dev-btop"
    tmux set-option -p -t "$btop_pane" remain-on-exit on

    # agent on the right of the top area (30%)
    set -l agent_pane (tmux split-window -h -l '30%' -t "$nvim_pane" -c "$repo" -P -F '#{pane_id}' $agent_cmd)
    tmux set-option -p -t "$agent_pane" @role "dev-$agent"
    tmux select-pane -t "$agent_pane" -T "dev-$agent"
    tmux set-option -p -t "$agent_pane" remain-on-exit on

    # nvim — focus and replace this fish process
    tmux set-option -p -t "$nvim_pane" @role "dev-$repo_name"
    tmux select-pane -t "$nvim_pane" -T "dev-$repo_name"
    tmux set-option -p -t "$nvim_pane" remain-on-exit on
    exec nvim .
end
