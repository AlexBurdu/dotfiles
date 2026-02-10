#!/usr/bin/env bash
# Symlinks Claude Code settings and global instructions into ~/.claude.
set -euo pipefail
source "$(dirname "$0")/../bash/link.sh"
echo "=== Claude Code — settings, instructions → ~/.claude ==="

# Backup existing config
if [ -d ~/.claude ]; then
  if [ -L ~/.claude.bak ]; then
    echo "Error: ~/.claude.bak is a symlink, refusing to overwrite"
    exit 1
  fi
  echo "Backing up existing ~/.claude to ~/.claude.bak..."
  rm -rf ~/.claude.bak
  cp -a ~/.claude ~/.claude.bak
  echo "Backup complete."
fi

# Create target directory
mkdir -p ~/.claude

# Symlink settings and global instructions
link "$(pwd)/settings.json" ~/.claude/settings.json \
  "Claude Code global settings (permissions, hooks for tmux status)"

link "$(pwd)/CLAUDE.md" ~/.claude/CLAUDE.md \
  "Global Claude Code instructions (commit format, conventions)"

# Install command groups
mkdir -p ~/.claude/commands
for group in commands/*/; do
  group_name=$(basename "$group")
  echo ""
  read -rp "Install $group_name commands? (y/n) " ans
  if [[ "$ans" == "y" ]]; then
    for cmd in "$group"*; do
      name=$(basename "$cmd")
      link "$(pwd)/$cmd" \
        ~/.claude/commands/"$group_name"-"${name%.md}".md \
        "Command /$group_name-${name%.md}"
    done
  fi
done
