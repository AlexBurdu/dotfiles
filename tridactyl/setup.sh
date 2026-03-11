#!/usr/bin/env bash
# Symlinks Tridactyl (Firefox vim-mode) config into ~/.config/tridactyl.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../bash/link.sh"
echo "=== Tridactyl — Firefox vim-mode keybindings → ~/.config/tridactyl ==="

link "$SCRIPT_DIR/tridactylrc" ~/.config/tridactyl/tridactylrc \
  "Tridactyl vim-mode keybindings for Firefox"
