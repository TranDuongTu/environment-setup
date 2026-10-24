#!/usr/bin/env bash
# C-b f: fuzzy-find files and open the selection in nvim in a new window of
# the current session. Launched by the tmux popup bind (see ~/.tmux.conf);
# the popup starts in the calling pane's directory (-d '#{pane_current_path}').
set -euo pipefail

selection="$(rg --files --hidden --glob '!.git' 2>/dev/null | fzf --multi --preview 'sed -n "1,120p" {}')"

printf '%s\n' "$selection" | while IFS= read -r file; do
  [ -n "$file" ] || continue
  session="$(tmux display -p '#S')"
  tmux new-window -t "$session" -n "$(basename "$file")" "nvim $(printf '%q' "$file")"
done