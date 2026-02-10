#!/usr/bin/env bash
# Symlinks Claude Code settings and global instructions into ~/.claude.
set -euo pipefail
source "$(dirname "$0")/../bash/link.sh"
echo "=== Claude Code — settings, instructions → ~/.claude ==="

# Backup existing config
if [ -d ~/.claude ]; then
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
