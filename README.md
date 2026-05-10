# Environment Setup

Bootstrap a new Ubuntu or macOS machine with my dev environment in one command.

## Quick Start

```bash
git clone <your-repo-url> ~/environment-setup
cd ~/environment-setup
chmod +x install.sh
./install.sh
```

The repo can be deleted after install — configs are copied to their standard locations, not symlinked.

## Prerequisites

- `sudo` access (Linux: for apt and `/usr/local/bin` installs)
- Internet connection (packages are fetched at install time)
- macOS: Xcode Command Line Tools (`xcode-select --install`) — Homebrew requires them

## What Gets Installed

### System Packages

| Tool | Version/Source | Platform |
|------|---------------|----------|
| Neovim | `neovim-ppa/unstable` PPA | Linux |
| Neovim | Homebrew | macOS |
| Tmux | apt | Linux |
| Tmux | Homebrew | macOS |
| Fish shell | apt | Linux |
| Fish shell | Homebrew | macOS |
| Git | apt | Linux |
| GitHub CLI (`gh`) | [cli.github.com](https://cli.github.com) apt repo | Linux |
| Lazygit | GitHub Releases (latest) | Linux |
| Node.js | NodeSource LTS | Linux |
| Go | [go.dev](https://go.dev) (latest stable) | Linux |
| kubectl | [dl.k8s.io](https://dl.k8s.io) (stable) | Linux |
| k9s | GitHub Releases (latest) | Linux |
| ripgrep | apt | Linux |
| fzf | apt | Linux |
| xclip | apt | Linux only |
| build-essential, cmake | apt | Linux |
| python3 | apt | Linux |
| All of the above | Homebrew | macOS |

### npm Global Packages

| Package | Purpose |
|---------|---------|
| `tree-sitter-cli` | Tree-sitter parser compilation for Neovim |

### Fonts

| Font | Source |
|------|--------|
| JetBrainsMono Nerd Font | [ryanoasis/nerd-fonts](https://github.com/ryanoasis/nerd-fonts) GitHub Releases |

Installed to `~/.local/share/fonts/JetBrainsMono/` and registered with `fc-cache`.

---

## Tool Configuration

### Neovim

Plugin manager: [lazy.nvim](https://github.com/folke/lazy.nvim) (auto-bootstrapped on first launch)

| Plugin | Purpose |
|--------|---------|
| `folke/tokyonight.nvim` | Colorscheme (night style) |
| `nvim-treesitter/nvim-treesitter` | Syntax highlighting (parsers: lua, vim, json, bash, markdown, markdown_inline) |
| `nvim-telescope/telescope.nvim` + `telescope-fzf-native.nvim` | Fuzzy finder |
| `nvim-neo-tree/neo-tree.nvim` (v3.x) | File explorer |
| `lewis6991/gitsigns.nvim` | Git diff signs in gutter |
| `sindrets/diffview.nvim` | Side-by-side diff view |
| `NeogitOrg/neogit` | Magit-style git UI (integrates with diffview + telescope) |
| `kdheepak/lazygit.nvim` | Lazygit float window |
| `akinsho/toggleterm.nvim` | Floating terminal (`C-\`) |
| `nvim-lualine/lualine.nvim` | Status line |
| `MeanderingProgrammer/render-markdown.nvim` | Rendered markdown in buffer |
| `folke/which-key.nvim` | Keymap hint popup |
| `nvim-tree/nvim-web-devicons` | File icons |
| `christoomey/vim-tmux-navigator` | Seamless pane navigation with tmux |

**Keybindings** (leader = `\`):

| Key | Action |
|-----|--------|
| `\ff` | Find files (Telescope) |
| `\fg` | Live grep (Telescope) |
| `\fb` | Buffers (Telescope) |
| `\fh` | Help tags (Telescope) |
| `\e` | Toggle Neo-tree |
| `\o` | Focus Neo-tree |
| `\gg` | Open LazyGit float |
| `\gd` | Diffview open |
| `\gc` | Diffview close |
| `\gh` | Current file history (Diffview) |
| `\gn` | Open Neogit |
| `C-\` | Toggle floating terminal |

---

### Tmux

Plugin manager: [TPM](https://github.com/tmux-plugins/tpm) (cloned to `~/.tmux/plugins/tpm`)

| Plugin | Purpose |
|--------|---------|
| `catppuccin/tmux` (frappe) | Status bar theme |
| `tmux-plugins/tmux-cpu` | CPU usage in status bar |
| `tmux-plugins/tmux-battery` | Battery status in status bar |
| `christoomey/vim-tmux-navigator` | Seamless pane navigation with Neovim |
| `sainnhe/tmux-fzf` | Fuzzy-find sessions, windows, and panes |

**Settings:**
- Status bar at top
- Mouse support off
- Pane borders show pane index and current command
- Clipboard via `xclip` (Linux)
- Pane switching: `C-h/j/k/l` (no prefix needed, via vim-tmux-navigator)

**Keybindings:**

| Key | Action |
|-----|--------|
| `C-b r` | Reload tmux config |
| `C-b W` | Open workspace launcher (fzf: layout → repo → agent) |
| `C-b F` | tmux-fzf: fuzzy-find sessions, windows, panes |

---

### Workspace Presets (tmuxinator)

Managed by [tmuxinator](https://github.com/tmuxinator/tmuxinator). Launch via `C-b W` in tmux (fzf picker) or from the shell with `ws`.

The launcher detects existing workspace sessions and lets you switch to them directly. For new sessions it prompts for layout, repo, and AI agent.

#### `workspace-big-screen`

Best for wide monitors. Single window, three panes:

```
┌──────────────────┬───────────────┐
│                  │  agent (30%)  │
│   nvim  (70%)    │               │
│                  │               │
├──────────────────┴───────────────┤
│        btop  (full width)        │
└──────────────────────────────────┘
```

- **Left (70%)** — Neovim, opened at the selected repo root
- **Top-right (30%)** — AI agent (`opencode`, `claude`, or `codex`)
- **Bottom (full width)** — `btop` system monitor

#### `workspace`

Three separate named windows — switch between them with `C-b n/p` or tmux-fzf (`C-b F → Window`):

| Window | Contents |
|--------|----------|
| `nvim` | Neovim at repo root |
| `agent` | AI agent |
| `btop` | System monitor |

#### Dynamic parameters

Both presets accept the repo path and agent at launch time via the fzf picker. You can also invoke them directly from the shell:

```bash
# Using the launcher function
ws

# Direct tmuxinator invocation
WORKSPACE_REPO=~/projects/myrepo WORKSPACE_AGENT=opencode tmuxinator start workspace-big-screen
WORKSPACE_REPO=~/projects/myrepo WORKSPACE_AGENT=claude tmuxinator start workspace
```

Repos are picked from `~/projects/` by default. Agent choices: `opencode`, `claude`, `codex`.

---

### Fish Shell

Plugin manager: [Oh My Fish](https://github.com/oh-my-fish/oh-my-fish) (installed to `~/.local/share/omf`)

| Plugin/Theme | Purpose |
|-------------|---------|
| `bobthefish` theme | Powerline-style prompt |

---

### Git

`~/.gitconfig` is copied from `configs/git/.gitconfig`. Uses `gh` as the credential helper.

---

## Config Deployment

Configs are **copied** to their standard locations (not symlinked). Re-running `install.sh` updates them in place, backing up any existing files to `<file>.bak`.

| Config source | Destination |
|---------------|-------------|
| `configs/nvim/` | `~/.config/nvim/` |
| `configs/tmux/.tmux.conf` | `~/.tmux.conf` |
| `configs/tmuxinator/` | `~/.config/tmuxinator/` |
| `configs/fish/` | `~/.config/fish/` |
| `configs/omf/` | `~/.config/omf/` |
| `configs/git/.gitconfig` | `~/.gitconfig` |

---

## Post-Install

The script is idempotent — re-run `./install.sh` at any time to update packages and redeploy configs. After each run, sync the running tools:

| Step | Action |
|------|--------|
| 1 | Set terminal font to **JetBrainsMono Nerd Font** and open a new terminal (fish shell activates) |
| 2 | Start tmux: `tmux` |
| 3 | Reload tmux config: `C-b r` |
| 4 | Reinstall tmux plugins: `C-b I` (wait for TPM to finish) |
| 5 | Open Neovim: `nvim` |
| 6 | Sync Neovim plugins: `:Lazy sync` |

**First install only:** lazy.nvim bootstraps itself automatically when Neovim first opens; tree-sitter parsers install on first file open. The bobthefish prompt loads automatically via OMF bundle.

## Repo Structure

```
configs/
├── nvim/
│   ├── init.lua
│   └── lazy-lock.json
├── tmux/
│   └── .tmux.conf
├── tmuxinator/
│   ├── workspace-big-screen.yml   # 70% nvim | 30% agent + btop
│   └── workspace.yml              # 3 windows: nvim, agent, btop
├── fish/
│   ├── config.fish
│   ├── fish_variables
│   ├── conf.d/
│   │   ├── omf.fish
│   │   ├── fish_frozen_key_bindings.fish
│   │   └── fish_frozen_theme.fish
│   └── functions/
│       └── ws.fish                # Workspace launcher (C-b W)
├── omf/
│   ├── bundle
│   ├── theme
│   └── channel
└── git/
    └── .gitconfig
```
