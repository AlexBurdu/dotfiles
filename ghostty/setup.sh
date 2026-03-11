#!/usr/bin/env bash
# Symlinks Ghostty terminal config and themes into ~/.config/ghostty.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../bash/link.sh"
echo "=== Ghostty — terminal config and themes → ~/.config/ghostty ==="

link "$SCRIPT_DIR/config" ~/.config/ghostty/config \
  "Ghostty terminal appearance and behavior settings"

link "$SCRIPT_DIR/themes" ~/.config/ghostty/themes \
  "Ghostty color themes (light/dark)"
