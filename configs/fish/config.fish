# Tool directories are added dynamically each startup instead of via
# `fish_add_path`, which persists expanded absolute paths into fish's
# universal variables ($HOME is baked in and the config stops being
# portable across users/machines). `not contains` keeps this idempotent
# for nested shells.

for dir in /opt/homebrew/bin $HOME/.local/bin $HOME/.opencode/bin
    if test -d $dir; and not contains $dir $PATH
        set -gx PATH $dir $PATH
    end
end

if status is-interactive
# Commands to run in interactive sessions can go here
end