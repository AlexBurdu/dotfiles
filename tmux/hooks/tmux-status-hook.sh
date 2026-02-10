#!/usr/bin/env bash
# Agent hook: updates the tmux window name to show current
# activity while working, and elapsed time while waiting.
#
# Designed to complement tmux-pilot, which sets meaningful
# session names (e.g., claude-fix-42). This hook only manages
# the window name to show agent state — no duplication.
#
# Usage: tmux-status-hook.sh <state>
#   activity  — PreToolUse: reads tool name from stdin JSON
#   working   — SessionStart / UserPromptSubmit
#   waiting   — Stop / AfterAgent
#   ready     — SessionEnd
#
# Dependencies: tmux, date

# Safety: if this file contains git conflict markers,
# exit silently instead of breaking all tool use.
# This file is symlinked from ~/.config/tmux/hooks/ into
# the dotfiles repo — git conflicts go live instantly.
if grep -q '^<<<<<<<' "$0" 2>/dev/null; then
  exit 0
fi

# Exit silently if not inside tmux.
[ -z "$TMUX" ] && exit 0

STATE="${1:-working}"
PANE_ID=$(tmux display-message -p '#{pane_id}')

# Map Claude Code / Gemini tool names to short labels.
map_tool() {
  case "$1" in
    Read|Glob|Grep)          echo "reading" ;;
    Write|Edit|NotebookEdit) echo "editing" ;;
    Bash)                    echo "running" ;;
    Task)                    echo "delegating" ;;
    WebFetch|WebSearch)      echo "searching" ;;
    *)                       echo "working" ;;
  esac
}

case "$STATE" in
  activity)
    # Fired on PreToolUse — extract tool name from stdin
    # JSON and show a human-readable activity label.
    input=$(cat)
    tool=$(printf '%s' "$input" \
      | grep -oE '"tool_name" *: *"[^"]*"' \
      | head -1 | sed 's/.*"\([^"]*\)"$/\1/')
    tmux rename-window -t "$PANE_ID" "$(map_tool "$tool")"
    ;;
  working)
    # Fired on SessionStart or UserPromptSubmit.
    tmux rename-window -t "$PANE_ID" "working"
    ;;
  waiting)
    # Fired on Stop / AfterAgent — show hand + timestamp
    # so user knows when the agent started waiting.
    ts=$(date +%H:%M)
    tmux rename-window -t "$PANE_ID" "✋${ts}"
    ;;
  ready)
    # Fired on SessionEnd — agent is done.
    tmux rename-window -t "$PANE_ID" "ready"
    ;;
esac

exit 0
