#!/bin/bash
# Theme picker popup for tmux — select dark, light, or auto (OS detection).
# Writes to ~/.local/share/tmux/mode and re-sources tmux config.

MODE_FILE=~/.local/share/tmux/mode
SET_CMD="mkdir -p ~/.local/share/tmux"

if [ -f "$MODE_FILE" ]; then
  current=$(cat "$MODE_FILE")
else
  current=auto
fi

# Marker for current selection
dk=" "; lt=" "; au=" "
case "$current" in
  dark)  dk="●";;
  light) lt="●";;
  *)     au="●";;
esac

tmux display-menu -T "Theme" \
  "$dk Dark"  d "run-shell '$SET_CMD; echo dark  > $MODE_FILE; tmux source-file ~/.config/tmux/tmux.conf'" \
  "$lt Light" l "run-shell '$SET_CMD; echo light > $MODE_FILE; tmux source-file ~/.config/tmux/tmux.conf'" \
  "$au Auto"  a "run-shell 'rm -f $MODE_FILE; tmux source-file ~/.config/tmux/tmux.conf'"
