#!/usr/bin/env bash
# Tests for install.sh deployment scoping.
#
#   ./test/install-test.sh [full|nvim|bad]
#
#   full  — ./install.sh        deploys every config (existing default behavior)
#   nvim  — ./install.sh nvim   deploys ONLY the Neovim config (+ plugin sync)
#   bad   — ./install.sh <bad>  exits 1 with usage, deploys nothing
#
# Every scenario runs in an isolated fake $HOME with stubbed binaries
# (brew, npm, herdr, nvim) so install.sh never touches the network or
# the real system. Set INSTALL_TRACE=1 to trace with `bash -x`.
set -u

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STUB_BIN="$(mktemp -d)"
KEEP_SANDBOX="${KEEP_SANDBOX:-}"
SANDBOXES=""
trap cleanup EXIT

pass=0
fail=0

say_ok()   { echo "[PASS] $1"; pass=$((pass+1)); }
say_fail() { echo "[FAIL] $1"; fail=$((fail+1)); }

assert_present() {
  if [ -e "$1" ]; then say_ok "present: $2"; else say_fail "missing: $2"; fi
}

assert_absent() {
  if [ -e "$1" ]; then say_fail "present (should not be): $2"; else say_ok "absent:  $2"; fi
}

assert_rc() {
  local expected="$1" actual="$2" desc="$3"
  if [ "$actual" = "$expected" ]; then say_ok "exit code $desc = $expected"
  else say_fail "exit code $desc: expected $expected, got $actual"; fi
}

cleanup() {
  if [ "$KEEP_SANDBOX" = "1" ]; then
    echo "keeping sandboxes: $SANDBOXES"
  else
    rm -rf $SANDBOXES
  fi
  rm -rf "$STUB_BIN"
}

# ── Sandbox setup ────────────────────────────────────────────────────────────

make_stubs() {
  # stubs exit 0 for everything: packages appear installed, headless nvim is a no-op
  for cmd in brew npm herdr nvim; do
    printf '#!/bin/sh\nexit 0\n' > "$STUB_BIN/$cmd"
    chmod +x "$STUB_BIN/$cmd"
  done
}

new_sandbox() {
  local home
  home="$(mktemp -d)"
  SANDBOXES="$SANDBOXES $home"
  SANDBOX="$home"
  mkdir -p "$home/.config"

  # Neovim state: lazy.nvim + lockfile + parsers present, stamp newer than
  # lock, so `nvim --headless` branches are skipped entirely.
  mkdir -p "$home/.local/share/nvim/lazy/lazy.nvim"
  mkdir -p "$home/.local/share/nvim/lazy/nvim-treesitter/parser"
  touch "$home/.local/share/nvim/lazy/nvim-treesitter/parser/markdown.so"
  touch "$home/.local/share/nvim/lazy/nvim-treesitter/parser/markdown_inline.so"
  mkdir -p "$home/.config/nvim"
  touch "$home/.config/nvim/lazy-lock.json"
  touch "$home/.local/share/nvim/lazy/.last-sync-stamp"

  # Other tools: pretend already installed so install.sh skips them
  mkdir -p "$home/Library/Fonts/JetBrainsMono"
  touch "$home/Library/Fonts/JetBrainsMono/.seeded"
  mkdir -p "$home/.tmux/plugins/tpm"
  mkdir -p "$home/.local/share/omf"
}

run_install() {
  local home="$1"
  shift
  local trace=""
  [ "${INSTALL_TRACE:-0}" = "1" ] && trace="-x"
  (
    cd "$REPO_DIR" &&
      env -u XDG_DATA_HOME -u XDG_DATA_DIRS -u XDG_CONFIG_HOME \
        HOME="$home" SHELL="$(command -v fish)" PATH="$STUB_BIN:$PATH" \
        PS4='[$LINENO] ' bash $trace ./install.sh "$@"
  ) > "$home/last-run.log" 2>&1
}

# ── Scenarios ────────────────────────────────────────────────────────────────

scenario_full() {
  echo "── scenario: full install (no argument) deploys everything"
  new_sandbox
  local rc
  run_install "$SANDBOX" ""
  rc=$?
  assert_rc 0 "$rc" "full install"
  assert_present "$SANDBOX/.config/nvim/init.lua"  "full: nvim config"
  assert_present "$SANDBOX/.tmux.conf"             "full: tmux config"
  assert_present "$SANDBOX/.config/fish"           "full: fish config"
  assert_present "$SANDBOX/.config/wezterm"        "full: wezterm config"
  assert_present "$SANDBOX/.config/ghostty/config" "full: ghostty config"
  assert_present "$SANDBOX/.config/omf"            "full: omf config"
  echo "    log: $SANDBOX/last-run.log"
}

scenario_nvim() {
  echo "── scenario: nvim-only install deploys just Neovim"
  new_sandbox
  local rc
  run_install "$SANDBOX" nvim
  rc=$?
  assert_rc 0 "$rc" "nvim install"
  assert_present "$SANDBOX/.config/nvim/init.lua" "nvim-only: nvim config deployed"
  assert_absent  "$SANDBOX/.tmux.conf"            "nvim-only: tmux config untouched"
  assert_absent  "$SANDBOX/.config/fish"          "nvim-only: fish config untouched"
  assert_absent  "$SANDBOX/.config/wezterm"       "nvim-only: wezterm config untouched"
  assert_absent  "$SANDBOX/.config/ghostty"       "nvim-only: ghostty config untouched"
  assert_absent  "$SANDBOX/.config/omf"           "nvim-only: omf config untouched"
  echo "    log: $SANDBOX/last-run.log"
}

scenario_bad() {
  echo "── scenario: unknown argument fails fast with usage"
  new_sandbox
  local rc
  run_install "$SANDBOX" frobnicate
  rc=$?
  assert_rc 1 "$rc" "unknown arg"
  assert_absent "$SANDBOX/.config/nvim/init.lua" "unknown arg: nothing deployed"
  echo "    log: $SANDBOX/last-run.log"
}

# ── Main ─────────────────────────────────────────────────────────────────────

make_stubs
case "${1:-all}" in
  full) scenario_full ;;
  nvim) scenario_nvim ;;
  bad)  scenario_bad ;;
  all)  scenario_full; scenario_nvim; scenario_bad ;;
  *)
    echo "Unknown scenario: $1 (use full|nvim|bad)" >&2
    exit 1
    ;;
esac

echo ""
echo "Passed: $pass, Failed: $fail"
[ "$fail" -eq 0 ]