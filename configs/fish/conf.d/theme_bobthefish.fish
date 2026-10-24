# bobthefish theme options.
# Global (not persisted universal variables), so nothing user- or
# machine-specific is baked into fish's variable store and the config stays
# portable. Values are read by the theme at prompt-render time.

# JetBrainsMono Nerd Font is installed by this repo: branch/pencil/etc glyphs.
# Rounded segment caps come from the shadowed __bobthefish_glyphs.fish.
set -g theme_nerd_fonts yes

# Project (git) segment: show the repo name only, not its parents.
set -g theme_show_project_parent no

# Right prompt: keep it empty (no command duration, no clock).
set -g theme_display_cmd_duration no
set -g theme_display_date no