#!/usr/bin/env bash
# Symlinks Karabiner-Elements keyboard remapping config into ~/.config/karabiner.
set -euo pipefail
source "$(dirname "$0")/../bash/link.sh"
echo "=== Karabiner-Elements — keyboard remapping → ~/.config/karabiner ==="

link "$(pwd)/karabiner.json" ~/.config/karabiner/karabiner.json \
  "Karabiner-Elements keyboard remapping rules"
