#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR=~/.claude
HOOKS_DIR="$CLAUDE_DIR/hooks"

mkdir -p "$HOOKS_DIR"

# Symlink global Claude Code settings
rm -f "$CLAUDE_DIR/settings.json"
ln -s "$SCRIPT_DIR/settings.json" \
  "$CLAUDE_DIR/settings.json"

# Symlink hook scripts
rm -f "$HOOKS_DIR/tmux-status-hook.sh"
ln -s "$SCRIPT_DIR/tmux-status-hook.sh" \
  "$HOOKS_DIR/tmux-status-hook.sh"

# Ensure hook script is executable
chmod +x "$SCRIPT_DIR/tmux-status-hook.sh"

echo "Claude Code hooks installed."
