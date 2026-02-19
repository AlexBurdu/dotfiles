#!/usr/bin/env bash
# Symlinks Neovim config, plugins, and keymaps into ~/.config/nvim.
set -euo pipefail
source "$(dirname "$0")/../bash/link.sh"
echo "=== Neovim — config, plugins, keymaps → ~/.config/nvim ==="

CONFIG_DIR=~/.config/nvim

# Backup existing config
if [ -d "$CONFIG_DIR" ]; then
  cp -r "$CONFIG_DIR" "${CONFIG_DIR}.bak"
fi

# Recursively create directories if they don't exist
mkdir -p "$CONFIG_DIR/lua/keymap" "$CONFIG_DIR/lua/plugins"

# Batch mode — skip individual prompts
all="n"
echo "Symlink all nvim plugins and configuration files?"
read -rp "If no (n), you will be prompted for each file. (y/n) " ans
if [[ "$ans" == "y" ]]; then
  all="a"
fi

# init.lua — offer copy vs symlink
if [[ "$all" != "a" ]]; then
  echo "Main entry point — loads lazy.nvim, keymaps, colors, and options"
  echo "  $(pwd)/init.lua → $CONFIG_DIR/init.lua"
  read -rp "Copy (c), symlink (s) or don't change (n)? " ans
else
  ans="s"
fi
if [[ "$ans" == "c" ]]; then
  rm -rf "$CONFIG_DIR/init.lua"
  cp "$(pwd)/init.lua" "$CONFIG_DIR/init.lua"
elif [[ "$ans" == "s" || "$all" == "a" ]]; then
  rm -rf "$CONFIG_DIR/init.lua"
  ln -s "$(pwd)/init.lua" "$CONFIG_DIR/init.lua"
fi

# Core lua directories — always symlink in batch mode
for entry in \
  "$(pwd)/lua/config|$CONFIG_DIR/lua/config|Core config — autocommands, diagnostics, general settings" \
  "$(pwd)/lua/color|$CONFIG_DIR/lua/color|Color scheme — sources and configures the active theme" \
  "$(pwd)/lua/options|$CONFIG_DIR/lua/options|Editor options — tabs, line numbers, clipboard, filetype mappings" \
  "$(pwd)/lua/lazy_nvim.lua|$CONFIG_DIR/lua/lazy_nvim.lua|Lazy.nvim — plugin manager bootstrap and loader"; do
  IFS='|' read -r src dst desc <<< "$entry"
  if [[ "$all" == "a" ]]; then
    mkdir -p "$(dirname "$dst")"
    rm -rf "$dst"
    ln -s "$src" "$dst"
  else
    link "$src" "$dst" "$desc"
  fi
done

# Plugin descriptions — used for per-file prompts
plugin_desc() {
  case "$1" in
    comment.lua)          echo "comment — toggle code comments with Ctrl-/" ;;
    copilot.lua)          echo "copilot — GitHub Copilot AI code completion" ;;
    dropbar.lua)          echo "dropbar — breadcrumb navigation bar showing code context" ;;
    fugitive.lua)         echo "fugitive — Git integration (status, diff, blame)" ;;
    lawrencium.lua)       echo "lawrencium — Mercurial (hg) integration (status, diff, log)" ;;
    lsp.lua)              echo "lsp — language server protocol with Mason and completion" ;;
    nightfox-theme.lua)   echo "nightfox — color theme with light/dark variants" ;;
    oil.lua)              echo "oil — file explorer (replaces netrw, supports trash)" ;;
    spectre.lua)          echo "spectre — project-wide find and replace" ;;
    telescope-zoxide.lua) echo "telescope-zoxide — jump to frequent dirs via zoxide" ;;
    telescope.lua)        echo "telescope — fuzzy finder for files, buffers, and grep" ;;
    tmux-navigator.lua)   echo "tmux-navigator — seamless Ctrl-h/j/k/l between nvim and tmux panes" ;;
    treesitter.lua)       echo "treesitter — syntax highlighting and code structure parsing" ;;
    trouble.lua)          echo "trouble — diagnostics list (errors, warnings, references)" ;;
    undotree.lua)         echo "undotree — visual undo history tree" ;;
    vim-signify.lua)      echo "vim-signify — git diff signs in the gutter" ;;
    wordmotion.lua)       echo "wordmotion — enhanced word-boundary navigation (camelCase, snake_case)" ;;
    zenmode.lua)          echo "zenmode — distraction-free focused editing mode" ;;
    surround.lua)         echo "surround — add, change, delete surrounding pairs (quotes, brackets)" ;;
    *)                    echo "$1" ;;
  esac
}

# Keymap modules
echo ""
echo "=== Keymap modules ==="
for file in "$(pwd)"/lua/keymap/*; do
  name=$(basename "$file")
  dst="$CONFIG_DIR/lua/keymap/$name"
  case "$name" in
    init.lua) desc="Keymap init — loads all keybinding modules" ;;
    *)        desc="Keymap: ${name%.lua} bindings" ;;
  esac
  if [[ "$all" == "a" ]]; then
    rm -rf "$dst"
    ln -s "$file" "$dst"
  else
    link "$file" "$dst" "$desc"
  fi
done

# Plugin modules
echo ""
echo "=== Plugin modules ==="
for file in "$(pwd)"/lua/plugins/*; do
  name=$(basename "$file")
  dst="$CONFIG_DIR/lua/plugins/$name"
  desc=$(plugin_desc "$name")
  if [[ "$all" == "a" ]]; then
    rm -rf "$dst"
    ln -s "$file" "$dst"
  else
    link "$file" "$dst" "$desc"
  fi
done
