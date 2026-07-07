# WezTerm Install + Borderless Config

**Date:** 2026-07-07
**Status:** Approved (design phase)
**Scope:** Add WezTerm to the environment bootstrap. Install binary idempotently on Ubuntu and macOS, deploy a borderless config via the existing copy-based pipeline. Replace nothing — WezTerm runs alongside GNOME Terminal / iTerm2.

## Goals

1. `install.sh` installs WezTerm on both supported OSes, idempotently, without introducing new patterns (no new apt repo, no abstraction layer).
2. A new `configs/wezterm/` source dir deploys a single `wezterm.lua` to `~/.config/wezterm/` using the existing `copy_dir` helper.
3. The deployed config is **fully borderless** (`window_decorations = "NONE"`), themed to match the rest of the environment (Dracula + JetBrainsMono Nerd Font), with keybindings that compensate for the missing title bar / tab bar.
4. `AGENTS.md` config-locations table gains a WezTerm row.
5. The final "Next steps" message in `install.sh` mentions WezTerm.

## Non-goals

- Replacing GNOME Terminal or iTerm2 as system default terminal handler (no `xdg-mime`, no `$TERMINAL` export, no fish alias).
- Configuring WezTerm multiplexing domains, SSH workspaces, or tmux-replacement features. The config stays minimal — appearance + keybindings only.
- Building from source.
- Window-manager integration (Wayland / GNOME Shell extensions) for true undecorated CSD on GNOME. WezTerm's own `window_decorations = "NONE"` is the mechanism used here.

## Install approach (Option A — GitHub release .deb + Homebrew)

Mirrors the existing `lazygit` (install.sh:89-98) and `k9s` (install.sh:129-138) blocks: one GitHub API call to discover the latest tag, one download, one install command. Same idempotency guard (`command_exists wezterm`).

### Linux (Ubuntu)

1. Skip if `command_exists wezterm`.
2. `WEZTERM_VERSION=$(curl -sL https://api.github.com/repositories/120568143/releases/latest | grep -Po '"tag_name":\s*"\K[^"]*')`
   - The repo was renamed; the `wez/wezterm` alias 301-redirects. Using the numeric repo ID avoids a redirect chain and is the same trick the existing lazygit/k9s blocks effectively rely on (those use the un-redirected path).
3. `curl -sLo /tmp/wezterm.deb "https://github.com/wez/wezterm/releases/download/${WEZTERM_VERSION}/wezterm-${WEZTERM_VERSION}.Ubuntu22.04.deb"`
   - Ubuntu 22.04 `.deb` is used for all supported Ubuntu versions (22.04, 24.04). No 24.04-specific asset exists in the release. The Ubuntu 22.04 deb installs cleanly on 24.04 (shared glibc-compatible deps). Ubuntu 20.04 is not officially supported by this script's WezTerm step — there is a separate `Ubuntu20.04.deb` asset, but adding 20.04 detection is out of scope (the script's own `add-apt-repository` and PPA usage already imply 22.04+). Verified against the `20240203-110809-5046fc22` release.
4. `sudo dpkg -i /tmp/wezterm.deb || sudo apt-get install -f -y -qq`
   - `apt-get install -f` pulls any missing deps (libssl, etc.) if `dpkg` reports broken deps.
5. `rm -f /tmp/wezterm.deb`
6. Idempotent: subsequent runs hit the `command_exists wezterm` guard and print `[OK] wezterm already installed`.

### macOS

Add `wezterm` to the Homebrew `packages=(...)` array in `install_packages_macos` (install.sh:163-170). Brew handles idempotency and upgrades. No separate function.

## Config — `configs/wezterm/wezterm.lua`

Single file. Deployed by a new `copy_dir "$CONFIGS_DIR/wezterm" "$HOME/.config/wezterm"` line in `deploy_configs` (install.sh:252), placed in the existing block alongside the nvim/tmux/fish entries.

### Contents

```lua
local wezterm = require('wezterm')
local config = wezterm.config_builder()

-- Appearance: fully borderless
config.window_decorations = 'NONE'
config.window_padding = { left = 0, right = 0, top = 0, bottom = 0 }

-- Font: matches the JetBrainsMono Nerd Font installed by install.sh:331
config.font = wezterm.font('JetBrainsMono Nerd Font')
config.font_size = 13.0

-- Color scheme: built-in WezTerm scheme, matches OMF bobthefish dracula
config.color_scheme = 'Dracula'

-- Tab bar: hidden when only one tab; otherwise visible (we still need
-- something to show tabs since decorations=NONE removes the OS title bar)
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false

-- Keys: compensate for missing window chrome
config.keys = {
  -- Window: move with Super+drag is native to WezTerm when decorations=NONE.
  -- Resize: handled by WezTerm's built-in Super+resize. No extra binding needed.

  -- Tabs (since no tab bar to click when only one tab is hidden)
  { key = 't', mods = 'CTRL|SHIFT', action = wezterm.action.SpawnTab('CurrentPaneDomain') },
  { key = 'w', mods = 'CTRL|SHIFT', action = wezterm.action.CloseCurrentTab({ confirm = true }) },
  { key = 'LeftArrow',  mods = 'CTRL|SHIFT', action = wezterm.action.ActivateTabRelative(-1) },
  { key = 'RightArrow', mods = 'CTRL|SHIFT', action = wezterm.action.ActivateTabRelative(1) },

  -- Split panes inside a tab
  { key = 'd', mods = 'CTRL|SHIFT',       action = wezterm.action.SplitHorizontal({ domain = 'CurrentPaneDomain' }) },
  { key = 'D', mods = 'CTRL|SHIFT',       action = wezterm.action.SplitVertical({ domain = 'CurrentPaneDomain' }) },
  { key = 'LeftArrow',  mods = 'CTRL|SHIFT|ALT', action = wezterm.action.ActivatePaneDirection('Left') },
  { key = 'RightArrow', mods = 'CTRL|SHIFT|ALT', action = wezterm.action.ActivatePaneDirection('Right') },
  { key = 'UpArrow',    mods = 'CTRL|SHIFT|ALT', action = wezterm.action.ActivatePaneDirection('Up') },
  { key = 'DownArrow',  mods = 'CTRL|SHIFT|ALT', action = wezterm.action.ActivatePaneDirection('Down') },
}

return config
```

### Design notes

- **Tab bar kept, hidden when single tab.** Even with `window_decorations = 'NONE'`, WezTerm can draw its own tab bar inside the window. Fully disabling the tab bar makes multi-tab invisible. Compromise: `hide_tab_bar_if_only_one_tab = true` gives a clean single-window look but surfaces tabs the moment you open a second one.
- **No tab-close / new-tab UI buttons.** `use_fancy_tab_bar = false` strips the GUI-style tab bar to a thin text strip — minimal chrome even when visible.
- **Pane bindings** mirror tmux's `Ctrl-b` split semantics loosely (`d` / `D`) so muscle memory transfers between tmux and WezTerm panes. Tmux is still the user's primary multiplexer; these bindings are a convenience, not a replacement.
- **No `$SHELL` override.** WezTerm reads `$SHELL` / `chsh` default; fish is already set as default shell by `set_fish_default` (install.sh:393).

## AGENTS.md update

Add a row to the config-locations table (AGENTS.md, "Config locations" section):

```
| WezTerm | `configs/wezterm/` | `~/.config/wezterm/` |
```

## install.sh wiring

- New function `install_wezterm()` placed after `install_tmuxinator()` (install.sh:290), in the same "tool installers" cluster. It is self-contained and guarded by `command_exists wezterm`, so it does not depend on the other installers' state — only on `curl`/`wget`/`sudo` being available, which `install_packages_*` guarantees.
- Called from `main()` immediately after `install_tmuxinator()` and before `setup_nvim`.
- `deploy_configs` gains a `copy_dir "$CONFIGS_DIR/wezterm" "$HOME/.config/wezterm"` line.
- `main()` final echo block gains: `  6. Run: wezterm  (borderless terminal — try Ctrl+Shift+T for a new tab)`.

## Error handling

- GitHub API unreachable → `curl` fails → `set -euo pipefail` aborts the script. Same behavior as the lazygit/k9s blocks. No new retry logic.
- `dpkg -i` reports broken deps → `apt-get install -f -y` resolves them. If that also fails, `set -e` aborts.
- macOS brew install of `wezterm` failure → brew exits non-zero → script aborts. Same as every other brew package.

## Testing

This repo has no automated tests (per AGENTS.md, testing is `./install.sh` + manual sync of running tools). Verification steps:

1. Run `./install.sh` on a clean Ubuntu 24.04 box → `which wezterm` returns `/usr/bin/wezterm`.
2. Run `./install.sh` again on the same box → prints `[OK] wezterm already installed`, no network calls.
3. On macOS, run `./install.sh` → `brew list wezterm` succeeds.
4. After deploy: `~/.config/wezterm/wezterm.lua` exists and `diff -q configs/wezterm/wezterm.lua ~/.config/wezterm/wezterm.lua` matches.
5. Launch `wezterm` → window opens with no title bar, no resize border, Dracula colors, JetBrainsMono font, zero padding.
6. `Ctrl+Shift+T` opens a second tab → thin tab bar appears. `Ctrl+Shift+W` closes it → tab bar disappears.
7. `Ctrl+Shift+D` and `Ctrl+Shift+Alt+Arrows` split and move between panes.

## File changes summary

| File | Change |
|------|--------|
| `install.sh` | + `install_wezterm()` function; +1 entry in macOS brew `packages`; +1 `copy_dir` line in `deploy_configs`; +1 line in `main()` final echo; +1 call in `main()` |
| `configs/wezterm/wezterm.lua` | new file (the config above) |
| `AGENTS.md` | +1 row in config-locations table |