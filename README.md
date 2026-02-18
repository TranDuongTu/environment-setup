# Environment Setup

Bootstrap a new Ubuntu or macOS machine with my dev environment in one command.

## Quick Start

```bash
git clone <your-repo-url> ~/environment-setup
cd ~/environment-setup
chmod +x install.sh
./install.sh
```

## What's Included

| Tool | Config |
|------|--------|
| Neovim | lazy.nvim, catppuccin-frappe, telescope, neo-tree, gitsigns, diffview, neogit, lualine, toggleterm, lazygit, render-markdown |
| Tmux | TPM, catppuccin-frappe, vim-style pane switching, status bar at top |
| Fish | Oh My Fish, bobthefish theme, dracula color scheme |
| Git | GitHub CLI credential helper |

## What `install.sh` Does

1. Detects OS (Ubuntu via apt, macOS via Homebrew)
2. Installs packages: neovim, tmux, fish, git, gh, lazygit, ripgrep, fzf, xclip (Linux), Node.js, Go, Python3, build-essential, cmake
3. Symlinks configs from the repo to their expected locations
4. Installs plugin managers (TPM, Oh My Fish)
5. Sets fish as default shell

The script is idempotent and safe to re-run.

## Post-Install

1. Open a new terminal (fish shell will be active)
2. Run `tmux`, then press `C-b I` to install tmux plugins via TPM
3. Run `nvim` -- lazy.nvim will auto-install all plugins on first launch
4. bobthefish theme with dracula colors loads automatically via OMF bundle

## Repo Structure

```
configs/
├── nvim/
│   ├── init.lua
│   └── lazy-lock.json
├── tmux/
│   └── .tmux.conf
├── fish/
│   ├── config.fish
│   ├── fish_variables
│   └── conf.d/
│       └── omf.fish
├── omf/
│   ├── bundle
│   ├── theme
│   └── channel
└── git/
    └── .gitconfig
```

## Neovim Keybindings

| Key | Action |
|-----|--------|
| `\ff` | Find files (Telescope) |
| `\fg` | Live grep (Telescope) |
| `\fb` | Buffers (Telescope) |
| `\fh` | Help tags (Telescope) |
| `\e` | Toggle Neo-tree |
| `\o` | Focus Neo-tree |
| `\gg` | Open LazyGit |
| `\gd` | Diffview open |
| `\gc` | Diffview close |
| `\gh` | File history (Diffview) |
| `\gn` | Open Neogit |
| `C-\` | Toggle floating terminal |
