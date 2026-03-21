#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIGS_DIR="$SCRIPT_DIR/configs"

# ── Helpers ───────────────────────────────────────────────────────────────────

info()  { printf '\033[1;34m[INFO]\033[0m  %s\n' "$*"; }
ok()    { printf '\033[1;32m[OK]\033[0m    %s\n' "$*"; }
warn()  { printf '\033[1;33m[WARN]\033[0m  %s\n' "$*"; }

command_exists() { command -v "$1" &>/dev/null; }

# ── Detect OS ─────────────────────────────────────────────────────────────────

detect_os() {
  case "$(uname -s)" in
    Linux*)  OS="linux" ;;
    Darwin*) OS="macos" ;;
    *)       echo "Unsupported OS: $(uname -s)"; exit 1 ;;
  esac
  info "Detected OS: $OS"
}

# ── Package Installation ─────────────────────────────────────────────────────

install_packages_linux() {
  local packages=(
    git curl wget unzip
    build-essential cmake
    ripgrep fzf xclip
    python3 python3-pip
    tmux fish
  )

  local missing=()
  for pkg in "${packages[@]}"; do
    if ! dpkg -s "$pkg" &>/dev/null; then
      missing+=("$pkg")
    fi
  done

  if [ ${#missing[@]} -gt 0 ]; then
    info "Installing missing apt packages: ${missing[*]}"
    sudo apt-get update -qq
    sudo apt-get install -y -qq "${missing[@]}"
  else
    ok "All apt packages already installed"
  fi

  # Neovim — use PPA for latest stable
  if ! command_exists nvim; then
    info "Installing Neovim via PPA..."
    sudo add-apt-repository -y ppa:neovim-ppa/unstable
    sudo apt-get update -qq
    sudo apt-get install -y -qq neovim
  else
    ok "Neovim already installed"
  fi

  # GitHub CLI
  if ! command_exists gh; then
    info "Installing GitHub CLI..."
    (type -p wget >/dev/null || sudo apt-get install wget -y) \
      && sudo mkdir -p -m 755 /etc/apt/keyrings \
      && out=$(mktemp) \
      && wget -nv -O "$out" https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      && cat "$out" | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
      && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
      && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
      && sudo apt-get update -qq \
      && sudo apt-get install -y -qq gh
  else
    ok "GitHub CLI already installed"
  fi

  # Lazygit
  if ! command_exists lazygit; then
    info "Installing lazygit..."
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": *"v\K[^"]*')
    curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf /tmp/lazygit.tar.gz -C /tmp lazygit
    sudo install /tmp/lazygit /usr/local/bin/lazygit
    rm -f /tmp/lazygit /tmp/lazygit.tar.gz
  else
    ok "lazygit already installed"
  fi

  # Node.js (via NodeSource)
  if ! command_exists node; then
    info "Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt-get install -y -qq nodejs
  else
    ok "Node.js already installed"
  fi

  # kubectl
  if ! command_exists kubectl; then
    info "Installing kubectl..."
    KUBECTL_VERSION=$(curl -sL https://dl.k8s.io/release/stable.txt)
    curl -sLo /tmp/kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 /tmp/kubectl /usr/local/bin/kubectl
    rm -f /tmp/kubectl
  else
    ok "kubectl already installed"
  fi

  # k9s
  if ! command_exists k9s; then
    info "Installing k9s..."
    K9S_VERSION=$(curl -s "https://api.github.com/repos/derailed/k9s/releases/latest" | grep -Po '"tag_name": *"\K[^"]*')
    curl -sLo /tmp/k9s.tar.gz "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_amd64.tar.gz"
    tar xf /tmp/k9s.tar.gz -C /tmp k9s
    sudo install /tmp/k9s /usr/local/bin/k9s
    rm -f /tmp/k9s /tmp/k9s.tar.gz
  else
    ok "k9s already installed"
  fi

  # Go
  if ! command_exists go; then
    info "Installing Go..."
    GO_VERSION=$(curl -s https://go.dev/VERSION?m=text | head -1)
    curl -Lo /tmp/go.tar.gz "https://go.dev/dl/${GO_VERSION}.linux-amd64.tar.gz"
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf /tmp/go.tar.gz
    rm -f /tmp/go.tar.gz
    export PATH="/usr/local/go/bin:$PATH"
  else
    ok "Go already installed"
  fi
}

install_packages_macos() {
  # Install Homebrew if missing
  if ! command_exists brew; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    ok "Homebrew already installed"
  fi

  local packages=(
    neovim tmux fish git gh lazygit
    ripgrep fzf
    node go python3
    cmake
    kubectl k9s
  )

  info "Installing Homebrew packages..."
  for pkg in "${packages[@]}"; do
    if brew list "$pkg" &>/dev/null; then
      ok "$pkg already installed"
    else
      brew install "$pkg"
    fi
  done
}

# ── NPM Global Tools ─────────────────────────────────────────────────────────

install_npm_globals() {
  if npm list -g tree-sitter-cli &>/dev/null; then
    ok "tree-sitter-cli already installed"
  else
    info "Installing tree-sitter-cli..."
    npm install -g tree-sitter-cli
    ok "tree-sitter-cli installed"
  fi
}

# ── Symlink Configs ──────────────────────────────────────────────────────────

symlink() {
  local src="$1" dest="$2"

  # Create parent directory if needed
  mkdir -p "$(dirname "$dest")"

  if [ -L "$dest" ]; then
    local current_target
    current_target="$(readlink "$dest")"
    if [ "$current_target" = "$src" ]; then
      ok "Symlink already correct: $dest"
      return
    fi
    warn "Updating symlink: $dest (was -> $current_target)"
    rm "$dest"
  elif [ -e "$dest" ]; then
    warn "Backing up existing file: $dest -> ${dest}.bak"
    mv "$dest" "${dest}.bak"
  fi

  ln -s "$src" "$dest"
  ok "Linked: $dest -> $src"
}

setup_symlinks() {
  info "Setting up config symlinks..."

  # Neovim — symlink the entire directory
  symlink "$CONFIGS_DIR/nvim" "$HOME/.config/nvim"

  # Tmux
  symlink "$CONFIGS_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"

  # Fish — symlink the entire directory
  symlink "$CONFIGS_DIR/fish" "$HOME/.config/fish"

  # Git
  symlink "$CONFIGS_DIR/git/.gitconfig" "$HOME/.gitconfig"

  # Oh My Fish config (theme, bundle)
  symlink "$CONFIGS_DIR/omf" "$HOME/.config/omf"
}

# ── Plugin Managers ──────────────────────────────────────────────────────────

install_tpm() {
  local tpm_dir="$HOME/.tmux/plugins/tpm"
  if [ -d "$tpm_dir" ]; then
    ok "TPM already installed"
  else
    info "Installing TPM (Tmux Plugin Manager)..."
    git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
    ok "TPM installed"
  fi
}

install_omf() {
  if [ -d "$HOME/.local/share/omf" ]; then
    ok "Oh My Fish already installed"
  else
    info "Installing Oh My Fish..."
    curl -L https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install > /tmp/omf-install.fish
    fish /tmp/omf-install.fish --noninteractive --yes
    rm -f /tmp/omf-install.fish
    ok "Oh My Fish installed"
  fi
}

# ── Fonts ────────────────────────────────────────────────────────────────────

install_fonts() {
  local font_dir="$HOME/.local/share/fonts/JetBrainsMono"

  if ls "$font_dir"/*.ttf &>/dev/null; then
    ok "JetBrainsMono Nerd Font already installed"
    return
  fi

  info "Installing JetBrainsMono Nerd Font..."
  mkdir -p "$font_dir"
  curl -Lo /tmp/JetBrainsMono.zip "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
  unzip -q /tmp/JetBrainsMono.zip -d "$font_dir"
  rm -f /tmp/JetBrainsMono.zip
  fc-cache -fv >/dev/null
  ok "JetBrainsMono Nerd Font installed"
}

# ── Neovim Bootstrap ─────────────────────────────────────────────────────────

setup_nvim() {
  local lazy_dir="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy"

  if [ -d "$lazy_dir/lazy.nvim" ]; then
    # lazy.nvim exists; check if lock file changed since last sync
    local lock_file="$HOME/.config/nvim/lazy-lock.json"
    local stamp_file="$lazy_dir/.last-sync-stamp"
    if [ -f "$stamp_file" ] && [ -f "$lock_file" ] && [ "$stamp_file" -nt "$lock_file" ]; then
      ok "Neovim plugins already synced"
    else
      info "Syncing Neovim plugins..."
      nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
      touch "$stamp_file"
      ok "Neovim plugins synced"
    fi
  else
    info "Bootstrapping Neovim plugins (lazy.nvim sync)..."
    nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
    mkdir -p "$lazy_dir"
    touch "$lazy_dir/.last-sync-stamp"
    ok "Neovim plugins installed"
  fi

  # Tree-sitter parsers — skip if parser dirs already exist
  local parser_dir="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy/nvim-treesitter/parser"
  if [ -f "$parser_dir/markdown.so" ] && [ -f "$parser_dir/markdown_inline.so" ]; then
    ok "Tree-sitter parsers already installed"
  else
    info "Installing tree-sitter parsers..."
    nvim --headless -c "TSInstall! markdown markdown_inline" +qa 2>/dev/null || true
    ok "Tree-sitter parsers installed"
  fi
}

# ── Set Default Shell ────────────────────────────────────────────────────────

set_fish_default() {
  local fish_path
  fish_path="$(which fish)"

  if [ "$SHELL" = "$fish_path" ]; then
    ok "Fish is already the default shell"
    return
  fi

  # Ensure fish is in /etc/shells
  if ! grep -qx "$fish_path" /etc/shells; then
    info "Adding fish to /etc/shells..."
    echo "$fish_path" | sudo tee -a /etc/shells >/dev/null
  fi

  info "Setting fish as default shell..."
  chsh -s "$fish_path"
  ok "Default shell set to fish (will take effect on next login)"
}

# ── Main ─────────────────────────────────────────────────────────────────────

main() {
  echo ""
  echo "=========================================="
  echo "  Environment Setup"
  echo "=========================================="
  echo ""

  detect_os

  # Install packages
  if [ "$OS" = "linux" ]; then
    install_packages_linux
  else
    install_packages_macos
  fi

  # NPM global tools
  install_npm_globals

  # Symlink configs
  setup_symlinks

  # Fonts
  install_fonts

  # Plugin managers
  install_tpm
  install_omf

  # Neovim bootstrap
  setup_nvim

  # Default shell
  set_fish_default

  echo ""
  echo "=========================================="
  echo "  Setup Complete!"
  echo "=========================================="
  echo ""
  echo "Next steps:"
  echo "  1. Set your terminal font to 'JetBrainsMono Nerd Font'"
  echo "  2. Open a new terminal (fish shell will be active)"
  echo "  3. Run: tmux"
  echo "     Then press C-b I to install tmux plugins via TPM"
  echo "  4. Run: nvim"
  echo "     lazy.nvim will auto-install all plugins on first launch"
  echo "  5. bobthefish theme (dracula colors) will load automatically via OMF bundle"
  echo ""
}

main "$@"
