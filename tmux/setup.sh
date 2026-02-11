#!/usr/bin/env bash
# Symlinks tmux config and shared hooks into ~/.config/tmux.
set -euo pipefail
source "$(dirname "$0")/../bash/link.sh"
echo "=== Tmux — config + hooks → ~/.config/tmux ==="

link "$(pwd)/tmux.conf" ~/.config/tmux/tmux.conf \
  "Tmux configuration (keybindings, plugins, catppuccin theme)"

link "$(pwd)/set-themes.sh" ~/.config/tmux/set-themes.sh \
  "Theme switcher (syncs light/dark across apps based on OS appearance)"

link "$(pwd)/hooks/tmux-status-hook.sh" ~/.config/tmux/hooks/tmux-status-hook.sh \
  "Agent hooks (tmux window name updates on agent state changes)"
