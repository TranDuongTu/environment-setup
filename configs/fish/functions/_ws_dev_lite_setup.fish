function _ws_dev_lite_setup --description "Internal: build dev-lite pane layout (nvim 50 / agent 50)"
    set -l repo (string trim -- "$WORKSPACE_REPO")
    set -l repo_name (string trim -- "$WORKSPACE_REPO_NAME")
    set -l agent (string trim -- "$WORKSPACE_AGENT")
    test -z "$repo"; and set repo $HOME
    test -z "$repo_name"; and set repo_name (basename "$repo")
    test -z "$agent"; and set agent "opencode"

    set -l win (tmux display-message -p "#{session_name}:#{window_index}")
    set -l nvim_pane (tmux display-message -p -t "$win.0" '#{pane_id}')

    # agent on the right (50%)
    set -l agent_pane (tmux split-window -h -l '50%' -t "$nvim_pane" -c "$repo" -P -F '#{pane_id}' $agent)
    tmux set-option -p -t "$agent_pane" @role "dev-lite-$agent"
    tmux select-pane -t "$agent_pane" -T "dev-lite-$agent"

    # nvim — focus and replace this fish process
    tmux set-option -p -t "$nvim_pane" @role "dev-lite-$repo_name"
    tmux select-pane -t "$nvim_pane" -T "dev-lite-$repo_name"
    exec nvim .
end
