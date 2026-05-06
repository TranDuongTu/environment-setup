if test -d /opt/homebrew/bin
    fish_add_path /opt/homebrew/bin
end

if status is-interactive
# Commands to run in interactive sessions can go here
end

fish_add_path $HOME/.local/bin

# opencode
fish_add_path /home/ttran/.opencode/bin
