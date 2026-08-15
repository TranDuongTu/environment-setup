local wezterm = require('wezterm')
local config = wezterm.config_builder()

-- Appearance: window with title bar and resize handles.
-- Force the X11 backend so GNOME/mutter draws GTK title-bar decorations;
-- under native Wayland the client renders borderless regardless of this flag.
config.enable_wayland = false
config.window_decorations = 'TITLE | RESIZE'

-- Font: matches the JetBrainsMono Nerd Font installed by install.sh
config.font = wezterm.font('JetBrainsMono Nerd Font')
config.font_size = 13.0

-- Color scheme: Rose Pine (https://github.com/neapsix/wezterm).
-- Per the plugin docs, `color_scheme` must NOT be set — it overrides the
-- custom `colors` table that the theme provides (including tab bar colors).
-- Variants: .main (dark), .moon (warmer dark), .dawn (light).
local theme = wezterm.plugin.require('https://github.com/neapsix/wezterm').main
config.colors = theme.colors()

-- Status/tab bar: bar.wezterm (https://github.com/adriankarlen/bar.wezterm)
-- Must be required AFTER colors are set so it can pick them up.
-- Bottom position; tmux status bar (trimmed to session+battery) stays on top.
-- Modules: cwd disabled (tmux's pane-border-format shows it per-pane since
-- tmux doesn't forward OSC 7 to wezterm); zoom enabled for tmux C-b z awareness;
-- username/hostname/clock explicitly enabled (defaults are on, but pin them
-- for clarity); spotify disabled (spotify-tui not installed).
local bar = wezterm.plugin.require('https://github.com/adriankarlen/bar.wezterm')
bar.apply_to_config(config, {
  modules = {
    cwd = { enabled = false },
    zoom = { enabled = true },
    username = { enabled = true },
    hostname = { enabled = true },
    clock = { enabled = true },
    spotify = { enabled = false },
  },
})

-- Tab bar: bar.wezterm styles the retro tab bar, so it must stay visible
-- even with a single tab (otherwise the status strip disappears).
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false
config.use_fancy_tab_bar = false

-- Scroll: default is 3 lines per wheel tick, which feels too fast.
-- Reduce to 1 line per tick. WezTerm replaces all default mouse bindings
-- when this table is set, so paste (middle-click) is included explicitly.
-- Bindings are duplicated for all modifier combos to prevent scroll events
-- from leaking to other windows (known X11 issue with certain compositors).
local function make_binding(event, action, mods)
  return { event = event, mods = mods, action = action }
end

local scroll_ev_up   = { Down = { streak = 1, button = { WheelUp = 1 } } }
local scroll_ev_down = { Down = { streak = 1, button = { WheelDown = 1 } } }
local paste_ev       = { Down = { streak = 1, button = 'Middle' } }

local mods_sets = { 'NONE', 'SHIFT', 'CTRL', 'ALT', 'SHIFT|CTRL', 'SHIFT|ALT', 'CTRL|ALT', 'SHIFT|CTRL|ALT' }
config.mouse_bindings = {}
for _, mods in ipairs(mods_sets) do
  table.insert(config.mouse_bindings, make_binding(scroll_ev_up,   wezterm.action.ScrollByLine(-1), mods))
  table.insert(config.mouse_bindings, make_binding(scroll_ev_down, wezterm.action.ScrollByLine(1), mods))
  table.insert(config.mouse_bindings, make_binding(paste_ev,       wezterm.action.PasteFrom('Clipboard'), mods))
end

config.bypass_mouse_reporting_modifiers = 'SHIFT'

-- Keys: compensate for missing window chrome and invisible tab bar
config.keys = {
  -- Tabs
  { key = 't', mods = 'CTRL|SHIFT', action = wezterm.action.SpawnTab('CurrentPaneDomain') },
  { key = 'w', mods = 'CTRL|SHIFT', action = wezterm.action.CloseCurrentTab({ confirm = true }) },
  { key = 'LeftArrow',  mods = 'CTRL|SHIFT', action = wezterm.action.ActivateTabRelative(-1) },
  { key = 'RightArrow', mods = 'CTRL|SHIFT', action = wezterm.action.ActivateTabRelative(1) },

  -- Fullscreen (Ctrl+Shift+F)
  { key = 'f', mods = 'CTRL|SHIFT', action = wezterm.action.ToggleFullScreen },

  -- Split panes inside a tab (mirrors tmux d/D muscle memory)
  { key = 'd', mods = 'CTRL|SHIFT', action = wezterm.action.SplitHorizontal({ domain = 'CurrentPaneDomain' }) },
  { key = 'D', mods = 'CTRL|SHIFT', action = wezterm.action.SplitVertical({ domain = 'CurrentPaneDomain' }) },
  { key = 'LeftArrow',  mods = 'CTRL|SHIFT|ALT', action = wezterm.action.ActivatePaneDirection('Left') },
  { key = 'RightArrow', mods = 'CTRL|SHIFT|ALT', action = wezterm.action.ActivatePaneDirection('Right') },
  { key = 'UpArrow',    mods = 'CTRL|SHIFT|ALT', action = wezterm.action.ActivatePaneDirection('Up') },
  { key = 'DownArrow',  mods = 'CTRL|SHIFT|ALT', action = wezterm.action.ActivatePaneDirection('Down') },
}

return config