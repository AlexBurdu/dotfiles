#!/usr/bin/env bash
# Symlinks Karabiner-Elements keyboard remapping config into ~/.config/karabiner.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../bash/link.sh"
echo "=== Karabiner-Elements — keyboard remapping → ~/.config/karabiner ==="

link "$SCRIPT_DIR/karabiner.json" ~/.config/karabiner/karabiner.json \
  "Karabiner-Elements keyboard remapping rules"
