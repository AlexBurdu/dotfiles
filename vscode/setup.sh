#!/usr/bin/env bash
# Symlinks VS Code keybindings and settings into the platform-specific config dir.
set -euo pipefail
source "$(dirname "$0")/../bash/link.sh"
echo "=== VS Code — keybindings and settings → platform config dir ==="

# Locations are different for Linux vs MacOS
CONFIG_DIR=~/.config/Code/User
if [[ "$OSTYPE" == "darwin"* ]]; then
  CONFIG_DIR=~/Library/Application\ Support/Code/User
fi

link "$(pwd)/keybindings.json" "${CONFIG_DIR}/keybindings.json" \
  "VS Code keyboard shortcuts (vim-consistent bindings)"

link "$(pwd)/settings.json" "${CONFIG_DIR}/settings.json" \
  "VS Code editor settings and preferences"
