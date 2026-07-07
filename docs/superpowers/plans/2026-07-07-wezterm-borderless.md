# WezTerm Borderless Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add WezTerm to the environment bootstrap — install the binary idempotently on Ubuntu/macOS and deploy a fully borderless `wezterm.lua` config via the existing copy-based pipeline.

**Architecture:** One new `install_wezterm()` function in `install.sh` follows the same shape as the existing `lazygit`/`k9s` blocks (GitHub release API → curl `.deb` → `dpkg -i`). macOS install piggybacks on the existing Homebrew loop. A new `configs/wezterm/wezterm.lua` deploys through the existing `copy_dir` helper. No abstraction, no symlinks.

**Tech Stack:** Bash (`install.sh`), Lua (WezTerm config), GitHub Releases API, apt/dpkg, Homebrew.

## Global Constraints

Copied verbatim from the spec / AGENTS.md:

- **Copy-based deployment, not symlinks.** Configs are copied to `~/.config/wezterm/` using the existing `copy_dir` helper. The repo does not need to exist post-install.
- **Idempotent.** Every new step in `install.sh` checks before acting. Re-running is always safe. The install block is guarded by `command_exists wezterm`; the config copy reuses `copy_dir` which diffs before writing.
- **No abstraction for its own sake.** The script is intentionally flat and readable. Don't introduce helper layers.
- **OS support:** Ubuntu 22.04+ and macOS. Ubuntu 20.04 is out of scope for the WezTerm step.
- **Borderless style:** `window_decorations = 'NONE'` (fully borderless — no title bar, no resize border).
- **Font:** JetBrainsMono Nerd Font, 13pt (matches the font installed at `install.sh:331`).
- **Color scheme:** `"Dracula"` (built-in WezTerm scheme, matches OMF bobthefish dracula).
- **Replace nothing:** WezTerm runs alongside the user's existing GNOME Terminal / iTerm2. No `xdg-mime`, no `$TERMINAL` export, no fish alias.

---

## File Structure

| File | Status | Responsibility |
|------|--------|----------------|
| `configs/wezterm/wezterm.lua` | Create | Single-file WezTerm config: borderless window, font, colors, tab bar rules, keybindings. |
| `install.sh` | Modify | Add `install_wezterm()` function; add `wezterm` to macOS brew `packages` array; add `copy_dir` line in `deploy_configs`; add call in `main()`; add next-steps echo. |
| `AGENTS.md` | Modify | Add WezTerm row to the config-locations table. |

Three files, three logical concerns: config, installer, docs. Each task below produces a self-contained, independently-verifiable change.

---

## Task 1: Create the WezTerm config file

**Files:**
- Create: `configs/wezterm/wezterm.lua`

**Interfaces:**
- Consumes: nothing (this is a standalone Lua file read by WezTerm at startup)
- Produces: a file at `configs/wezterm/wezterm.lua` that Task 2's `copy_dir "$CONFIGS_DIR/wezterm" "$HOME/.config/wezterm"` will deploy to `~/.config/wezterm/wezterm.lua`

- [ ] **Step 1: Create the directory**

```bash
mkdir -p configs/wezterm
```

- [ ] **Step 2: Write `configs/wezterm/wezterm.lua`**

Exact contents:

```lua
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
```

- [ ] **Step 3: Verify the file parses as valid Lua**

Run: `luac -p configs/wezterm/wezterm.lua && echo OK`
Expected output: `OK`

If `luac` is not installed, fall back to a syntax sanity check:
```bash
grep -c "return config" configs/wezterm/wezterm.lua
```
Expected output: `1`

(Note: `luac` only checks syntax, not WezTerm semantics. Full verification happens at Task 3 step 5 when `wezterm` is actually launched.)

- [ ] **Step 4: Commit**

```bash
git add configs/wezterm/wezterm.lua
git commit -m "add wezterm borderless config"
```

---

## Task 2: Wire WezTerm install + deploy into `install.sh`

**Files:**
- Modify: `install.sh` (multiple sections — exact line anchors below)

**Interfaces:**
- Consumes: `configs/wezterm/wezterm.lua` from Task 1; existing `copy_dir` helper (install.sh:221); existing `command_exists` helper (install.sh:23); existing `info`/`ok`/`warn` helpers (install.sh:19-21); existing `OS` variable set by `detect_os` (install.sh:27)
- Produces: an installed `wezterm` binary on PATH and a deployed `~/.config/wezterm/wezterm.lua`

- [ ] **Step 1: Add `wezterm` to the macOS Homebrew packages array**

In `install.sh`, find the `install_packages_macos()` function's `local packages=(...)` block (currently around install.sh:163-170). Add `wezterm` to the list. The array currently reads:

```bash
  local packages=(
    neovim tmux fish git gh lazygit
    ripgrep fzf
    node go python3
    cmake
    kubectl k9s
    ruby tmuxinator
  )
```

Change it to:

```bash
  local packages=(
    neovim tmux fish git gh lazygit wezterm
    ripgrep fzf
    node go python3
    cmake
    kubectl k9s
    ruby tmuxinator
  )
```

(Adding `wezterm` on the first line next to `lazygit` keeps related GUI/CLI tools grouped.)

- [ ] **Step 2: Add the `install_wezterm()` function**

Place it immediately after the `install_tmuxinator()` function (which ends at install.sh:302 with the closing `}`). Insert this block between `install_tmuxinator()` and the `# ── Plugin Managers ───...` comment header (install.sh:304):

```bash

# ── WezTerm ──────────────────────────────────────────────────────────────────

install_wezterm() {
  if command_exists wezterm; then
    ok "wezterm already installed"
    return
  fi

  if [ "$OS" = "macos" ]; then
    # macOS install is handled by the Homebrew packages array in
    # install_packages_macos. This branch should not be reached because
    # brew installs wezterm before this function runs, but guard anyway.
    info "Installing wezterm via Homebrew..."
    brew install wezterm
    ok "wezterm installed"
    return
  fi

  info "Installing wezterm..."
  WEZTERM_VERSION=$(curl -sL https://api.github.com/repositories/120568143/releases/latest | grep -Po '"tag_name":\s*"\K[^"]*')
  curl -sLo /tmp/wezterm.deb "https://github.com/wez/wezterm/releases/download/${WEZTERM_VERSION}/wezterm-${WEZTERM_VERSION}.Ubuntu22.04.deb"
  sudo dpkg -i /tmp/wezterm.deb || sudo apt-get install -f -y -qq
  rm -f /tmp/wezterm.deb
  ok "wezterm installed"
}
```

Notes for the implementer:
- The `wez/wezterm` GitHub repo 301-redirects to the numeric repo ID `120568143`. Using the numeric ID in the API URL avoids a redirect chain (the un-redirected `api.github.com/repos/wez/wezterm/releases/latest` returns 301 and `curl -s` without `-L` would fail to follow it). The download URL uses the `wez/wezterm` path because the release assets redirect cleanly from there.
- `Ubuntu22.04.deb` is used for all supported Ubuntu versions (22.04, 24.04). No 24.04-specific asset exists. The 22.04 deb installs cleanly on 24.04.
- `sudo dpkg -i ... || sudo apt-get install -f -y` resolves missing deps if `dpkg` reports broken deps. Both commands exit non-zero on real failure, so `set -euo pipefail` aborts the script on genuine errors.

- [ ] **Step 3: Add the WezTerm config deployment to `deploy_configs()`**

In `deploy_configs()` (install.sh:252-286), find the Git config block:

```bash
  # Git
  copy_file "$CONFIGS_DIR/git/.gitconfig" "$HOME/.gitconfig"
```

Immediately after that block and before the `# Oh My Fish config` comment, insert:

```bash

  # WezTerm
  copy_dir "$CONFIGS_DIR/wezterm" "$HOME/.config/wezterm"
```

- [ ] **Step 4: Add the `install_wezterm` call to `main()`**

In `main()` (install.sh:415-465), find the call to `install_tmuxinator`:

```bash
  # Plugin managers
  install_tpm
  install_omf
  install_tmuxinator
```

Immediately after `install_tmuxinator`, add:

```bash
  install_wezterm
```

(The function is self-contained and guarded by `command_exists wezterm`, so it does not depend on the other installers' state — only on `curl`/`wget`/`sudo` being available, which `install_packages_*` guarantees.)

- [ ] **Step 5: Add the WezTerm next-steps line to `main()`'s final echo block**

In `main()`'s "Next steps" echo block (install.sh:456-464), after the line:

```bash
  echo "  5. bobthefish theme (dracula colors) will load automatically via OMF bundle"
```

add:

```bash
  echo "  6. Run: wezterm  (borderless terminal — try Ctrl+Shift+T for a new tab)"
```

- [ ] **Step 6: Verify the script is still valid bash**

Run: `bash -n install.sh && echo OK`
Expected output: `OK`

(`bash -n` parses but does not execute — catches syntax errors without triggering the install.)

- [ ] **Step 7: Commit**

```bash
git add install.sh
git commit -m "add wezterm install + config deploy to install.sh"
```

---

## Task 3: Update `AGENTS.md` config-locations table

**Files:**
- Modify: `AGENTS.md` (the "Config locations" table, lines 18-24)

**Interfaces:**
- Consumes: the existing config-locations table
- Produces: a documented WezTerm row so future contributors know where the source-of-truth config lives

- [ ] **Step 1: Add the WezTerm row**

In `AGENTS.md`, find the config-locations table:

```
| Tool | Source | Deployed to |
|------|--------|-------------|
| Neovim | `configs/nvim/` | `~/.config/nvim/` |
| Tmux | `configs/tmux/.tmux.conf` | `~/.tmux.conf` |
| Fish | `configs/fish/` | `~/.config/fish/` |
| OMF | `configs/omf/` | `~/.config/omf/` |
| Git | `configs/git/.gitconfig` | `~/.gitconfig` |
```

Add a new row after the Git row:

```
| WezTerm | `configs/wezterm/` | `~/.config/wezterm/` |
```

The full table becomes:

```
| Tool | Source | Deployed to |
|------|--------|-------------|
| Neovim | `configs/nvim/` | `~/.config/nvim/` |
| Tmux | `configs/tmux/.tmux.conf` | `~/.tmux.conf` |
| Fish | `configs/fish/` | `~/.config/fish/` |
| OMF | `configs/omf/` | `~/.config/omf/` |
| Git | `configs/git/.gitconfig` | `~/.gitconfig` |
| WezTerm | `configs/wezterm/` | `~/.config/wezterm/` |
```

- [ ] **Step 2: Commit**

```bash
git add AGENTS.md
git commit -m "document wezterm config location in AGENTS.md"
```

---

## Task 4: End-to-end verification

**Files:**
- None modified — verification only.

**Interfaces:**
- Consumes: all changes from Tasks 1-3
- Produces: evidence that the full flow works (binary installed, config deployed, borderless window renders)

This repo has no automated test suite (per AGENTS.md: "Test changes by running `./install.sh` and then syncing running tools"). Verification is manual.

- [ ] **Step 1: Run `bash -n install.sh` one more time**

Run: `bash -n install.sh && echo OK`
Expected output: `OK`

- [ ] **Step 2: Confirm `configs/wezterm/wezterm.lua` exists and is non-empty**

Run: `test -s configs/wezterm/wezterm.lua && echo OK`
Expected output: `OK`

- [ ] **Step 3: Confirm `AGENTS.md` has the WezTerm row**

Run: `grep -q "WezTerm | \`configs/wezterm/\`" AGENTS.md && echo OK`
Expected output: `OK`

- [ ] **Step 4: Run `./install.sh` on Ubuntu 24.04**

Run: `./install.sh`
Expected: script runs to completion; during the new WezTerm step, prints either:
- `[OK] wezterm already installed` (if previously installed), or
- `[INFO] Installing wezterm...` followed by `[OK] wezterm installed`

Then during `deploy_configs`, prints either:
- `[OK] Already up-to-date: /home/<user>/.config/wezterm` (if config unchanged), or
- `[OK] Copied: configs/wezterm -> /home/<user>/.config/wezterm`

- [ ] **Step 5: Verify the binary is on PATH**

Run: `which wezterm`
Expected output: `/usr/bin/wezterm`

- [ ] **Step 6: Verify the deployed config matches the source**

Run: `diff -q configs/wezterm/wezterm.lua ~/.config/wezterm/wezterm.lua && echo OK`
Expected output: `OK`

- [ ] **Step 7: Verify WezTerm loads the config without errors**

Run: `wezterm --config-file ~/.config/wezterm/wezterm.lua show-keys 2>&1 | head -5`
Expected: a list of keybindings including the `Ctrl+Shift+T` / `Ctrl+Shift+W` entries. No Lua errors, no "unknown config option" warnings.

- [ ] **Step 8: Launch WezTerm and confirm borderless visually**

Run: `wezterm &`
Expected: a window opens with:
- No OS title bar
- No resize border
- Dracula color scheme (dark background, light text)
- JetBrainsMono Nerd Font
- Content flush against all four window edges (zero padding)

Then test the keybindings:
- `Ctrl+Shift+T` → opens a second tab; a thin text tab bar appears at the top
- `Ctrl+Shift+W` → closes the second tab; tab bar disappears
- `Ctrl+Shift+D` → splits the current pane horizontally
- `Ctrl+Shift+Alt+Arrow` → moves focus between panes

- [ ] **Step 9: Re-run `./install.sh` to confirm idempotency**

Run: `./install.sh`
Expected: during the WezTerm install step, prints `[OK] wezterm already installed`. During `deploy_configs`, prints `[OK] Already up-to-date: /home/<user>/.config/wezterm`. No network calls for the install step, no file writes for the config step.

- [ ] **Step 10: (If on macOS) verify the Homebrew path**

Run: `brew list wezterm >/dev/null && echo OK`
Expected output: `OK`

(Skip this step on Linux.)