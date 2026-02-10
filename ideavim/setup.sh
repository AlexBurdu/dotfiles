#!/usr/bin/env bash
# Symlinks IdeaVim config files into ~/.config/ideavim and
# links ~/.ideavimrc for IntelliJ to pick up.
set -euo pipefail
source "$(dirname "$0")/../bash/link.sh"
echo "=== IdeaVim — vim bindings for IntelliJ → ~/.config/ideavim ==="

CONFIG_DIR=~/.config/ideavim

# Descriptions for each .vim file
vim_desc() {
  case "$1" in
    ideavimrc.vim)     echo "IdeaVim main config — leader key, IDE action mappings, plugin emulation" ;;
    copilot.vim)       echo "copilot — GitHub Copilot keybindings for IntelliJ" ;;
    gemini.vim)        echo "gemini — Google Gemini AI code completion actions" ;;
    intellijbazel.vim) echo "intellijbazel — Bazel build actions, jump to BUILD files" ;;
    *)                 echo "$1" ;;
  esac
}

# Backup existing config
if [ -d "$CONFIG_DIR" ]; then
  cp -r "$CONFIG_DIR" "${CONFIG_DIR}.bak"
fi

mkdir -p "$CONFIG_DIR"

# Symlink all .vim files
for file in "$(pwd)"/*.vim; do
  name=$(basename "$file")
  desc=$(vim_desc "$name")
  link "$file" "$CONFIG_DIR/$name" "$desc"
done

# Link ideavimrc.vim to ~/.ideavimrc (IntelliJ reads from home dir)
rm -f ~/.ideavimrc
ln -s "$CONFIG_DIR/ideavimrc.vim" ~/.ideavimrc
echo "Linked ~/.ideavimrc → $CONFIG_DIR/ideavimrc.vim"
