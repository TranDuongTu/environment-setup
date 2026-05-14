function _ws_dev_lite_setup --description "Internal: build dev-lite windows (nvim / agent / btop, each full-screen tab)"
    set -l repo (string trim -- "$WORKSPACE_REPO")
    set -l repo_name (string trim -- "$WORKSPACE_REPO_NAME")
    set -l agent (string trim -- "$WORKSPACE_AGENT")
    test -z "$repo"; and set repo $HOME
    test -z "$repo_name"; and set repo_name (basename "$repo")
    test -z "$agent"; and set agent "opencode"

    set -l agent_cmd $agent
    test "$agent" = "claude"; and set agent_cmd "claude --dangerously-skip-permissions"

    set -l session (tmux display-message -p '#{session_name}')

    # agent window (new tab)
    tmux new-window -t "$session:" -n "dev-lite-$agent" -c "$repo" $agent_cmd

    # btop window (new tab)
    tmux new-window -t "$session:" -n "dev-lite-btop" -c "$repo" btop

    # back to first window for nvim
    tmux select-window -t "$session:0"
    exec nvim .
end
