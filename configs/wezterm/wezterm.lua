local wezterm = require('wezterm')
local config = wezterm.config_builder()

-- Appearance: fully borderless
config.window_decorations = 'NONE'
config.window_padding = { left = 0, right = 0, top = 0, bottom = 0 }

-- Font: matches the JetBrainsMono Nerd Font installed by install.sh
config.font = wezterm.font('JetBrainsMono Nerd Font')
config.font_size = 13.0

-- Color scheme: built-in WezTerm scheme, matches OMF bobthefish dracula
config.color_scheme = 'Dracula'

-- Tab bar: hidden when only one tab; thin text strip when multiple
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false

-- Keys: compensate for missing window chrome and invisible tab bar
config.keys = {
  -- Tabs
  { key = 't', mods = 'CTRL|SHIFT', action = wezterm.action.SpawnTab('CurrentPaneDomain') },
  { key = 'w', mods = 'CTRL|SHIFT', action = wezterm.action.CloseCurrentTab({ confirm = true }) },
  { key = 'LeftArrow',  mods = 'CTRL|SHIFT', action = wezterm.action.ActivateTabRelative(-1) },
  { key = 'RightArrow', mods = 'CTRL|SHIFT', action = wezterm.action.ActivateTabRelative(1) },

  -- Split panes inside a tab (mirrors tmux d/D muscle memory)
  { key = 'd', mods = 'CTRL|SHIFT', action = wezterm.action.SplitHorizontal({ domain = 'CurrentPaneDomain' }) },
  { key = 'D', mods = 'CTRL|SHIFT', action = wezterm.action.SplitVertical({ domain = 'CurrentPaneDomain' }) },
  { key = 'LeftArrow',  mods = 'CTRL|SHIFT|ALT', action = wezterm.action.ActivatePaneDirection('Left') },
  { key = 'RightArrow', mods = 'CTRL|SHIFT|ALT', action = wezterm.action.ActivatePaneDirection('Right') },
  { key = 'UpArrow',    mods = 'CTRL|SHIFT|ALT', action = wezterm.action.ActivatePaneDirection('Up') },
  { key = 'DownArrow',  mods = 'CTRL|SHIFT|ALT', action = wezterm.action.ActivatePaneDirection('Down') },
}

return config