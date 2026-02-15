#!/usr/bin/env bash
# Symlinks tmux config and shared hooks into ~/.config/tmux.
set -euo pipefail
source "$(dirname "$0")/../bash/link.sh"
echo "=== Tmux — config + hooks → ~/.config/tmux ==="

link "$(pwd)/tmux.conf" ~/.config/tmux/tmux.conf \
  "Tmux configuration (keybindings, plugins, catppuccin theme)"

link "$(pwd)/set-themes.sh" ~/.config/tmux/set-themes.sh \
  "Theme switcher (syncs light/dark across apps based on OS appearance)"

link "$(pwd)/theme-picker.sh" ~/.config/tmux/theme-picker.sh \
  "Theme picker popup (dark/light/auto selection menu)"

link "$(pwd)/hooks/tmux-status-hook.sh" ~/.config/tmux/hooks/tmux-status-hook.sh \
  "Agent hooks (tmux window name updates on agent state changes)"

link "$(pwd)/hooks/sync-claude-theme.sh" ~/.config/tmux/hooks/sync-claude-theme.sh \
  "Claude Code theme sync (matches dark/light mode on session start)"

# Install TPM (Tmux Plugin Manager)
if [ ! -d ~/.tmux/plugins/tpm ]; then
  echo ""
  echo "TPM (Tmux Plugin Manager) is not installed."
  echo "It manages tmux plugins like catppuccin and tmux-pilot."
  echo ""
  read -rp "Install TPM? (Y/n) " response
  echo ""
  if [ "$response" != "n" ]; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  fi
fi

# Install tmux plugins via TPM
if [ -x ~/.tmux/plugins/tpm/bin/install_plugins ]; then
  echo ""
  read -rp "Install/update tmux plugins (catppuccin, tmux-pilot)? (Y/n) " response
  echo ""
  if [ "$response" != "n" ]; then
    ~/.tmux/plugins/tpm/bin/install_plugins
  fi
fi
