#!/usr/bin/env bash
# Sync Claude Code theme with the current tmux dark/light mode.
# Reads ~/.local/share/tmux/theme (written by set-themes.sh)
# and updates ~/.claude.json via jq.
#
# Called from:
#   - set-themes.sh init (on theme switch)
#   - Claude Code SessionStart hook (new/resumed sessions)

THEME_FILE=~/.local/share/tmux/theme

# Exit silently if theme file or jq are missing.
[ -f "$THEME_FILE" ] || exit 0
command -v jq >/dev/null || exit 0

mode=$(cat "$THEME_FILE")
case "$mode" in
  dark)  claude_theme="dark-daltonized" ;;
  light) claude_theme="light" ;;
  *)     exit 0 ;;
esac

CLAUDE_JSON=~/.claude.json

# Read current theme (empty string if file missing or key absent).
current=$(jq -r '.theme // empty' "$CLAUDE_JSON" 2>/dev/null)
[ "$current" = "$claude_theme" ] && exit 0

# Update or create the file.
if [ -f "$CLAUDE_JSON" ]; then
  tmp=$(mktemp)
  jq --arg t "$claude_theme" '.theme = $t' "$CLAUDE_JSON" > "$tmp" && mv "$tmp" "$CLAUDE_JSON"
else
  printf '{"theme":"%s"}\n' "$claude_theme" > "$CLAUDE_JSON"
fi
