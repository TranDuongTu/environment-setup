local wezterm = require('wezterm')
local config = wezterm.config_builder()

-- Appearance: window with title bar and resize handles
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
config.mouse_bindings = {
  {
    event = { Down = { streak = 1, button = { WheelUp = 1 } } },
    mods = 'NONE',
    action = wezterm.action.ScrollByLine(-1),
  },
  {
    event = { Down = { streak = 1, button = { WheelDown = 1 } } },
    mods = 'NONE',
    action = wezterm.action.ScrollByLine(1),
  },
  {
    event = { Down = { streak = 1, button = 'Middle' } },
    mods = 'NONE',
    action = wezterm.action.PasteFrom('Clipboard'),
  },
}

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