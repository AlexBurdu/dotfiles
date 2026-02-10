#!/usr/bin/env bash
# Symlinks Tridactyl (Firefox vim-mode) config into ~/.config/tridactyl.
set -euo pipefail
source "$(dirname "$0")/../bash/link.sh"
echo "=== Tridactyl — Firefox vim-mode keybindings → ~/.config/tridactyl ==="

link "$(pwd)/tridactylrc" ~/.config/tridactyl/tridactylrc \
  "Tridactyl vim-mode keybindings for Firefox"
