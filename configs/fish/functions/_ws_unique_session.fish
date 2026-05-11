function _ws_unique_session --description "Return unique tmux session name; prompt for suffix if base collides"
    set -l base $argv[1]
    test -z "$base"; and return 1

    if not tmux has-session -t "=$base" 2>/dev/null
        echo $base
        return 0
    end

    # Collision — list existing matches, prompt for suffix on stderr
    set -l matches (tmux list-sessions -F "#S" 2>/dev/null | string match -r "^$base(\$|-.*)")
    echo "Session '$base' already exists. Existing:" >&2
    for m in $matches
        echo "  - $m" >&2
    end

    while true
        read -P "Suffix (empty = cancel) > " suffix
        test -z "$suffix"; and return 1

        # Sanitize: tmux dislikes ':' and '.'
        set suffix (string replace -ra '[^A-Za-z0-9_-]' '-' -- $suffix)
        set -l candidate "$base-$suffix"
        if not tmux has-session -t "=$candidate" 2>/dev/null
            echo $candidate
            return 0
        end
        echo "'$candidate' also exists. Try another." >&2
    end
end
