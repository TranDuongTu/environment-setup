# AGENTS.md

This repo is a personal dev environment bootstrap. It installs and configures Neovim, tmux, Fish shell, and supporting CLI tools on Ubuntu or macOS.

## What this repo does

- `install.sh` — idempotent setup script: installs system packages, copies configs, installs plugin managers, sets fish as default shell
- `configs/` — source-of-truth for all tool configs; changes here are deployed by re-running `install.sh`

## Key constraints

- **Copy-based deployment, not symlinks.** Configs are copied to their standard locations (`~/.config/nvim`, `~/.tmux.conf`, etc.). The repo does not need to exist post-install.
- **Idempotent.** Every step in `install.sh` checks before acting. Re-running is always safe.
- **No abstraction for its own sake.** The script is intentionally flat and readable. Don't introduce helper layers unless a concrete need exists.

## Config locations

| Tool | Source | Deployed to |
|------|--------|-------------|
| Neovim | `configs/nvim/` | `~/.config/nvim/` |
| Tmux | `configs/tmux/.tmux.conf` | `~/.tmux.conf` |
| Fish | `configs/fish/` | `~/.config/fish/` |
| OMF | `configs/omf/` | `~/.config/omf/` |
| Git | `configs/git/.gitconfig` | `~/.gitconfig` |
| WezTerm | `configs/wezterm/` | `~/.config/wezterm/` |

## Making changes

- Edit config files under `configs/` — never edit deployed paths directly
- Test changes by running `./install.sh` and then syncing running tools:
  - tmux: `C-b r` (reload), `C-b I` (reinstall plugins)
  - Neovim: `:Lazy sync`
- Plugin lists live in `configs/nvim/init.lua` (lazy.nvim) and `configs/tmux/.tmux.conf` (TPM)
