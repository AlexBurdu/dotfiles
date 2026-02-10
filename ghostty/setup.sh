#!/usr/bin/env bash
# Symlinks Ghostty terminal config and themes into ~/.config/ghostty.
set -euo pipefail
source "$(dirname "$0")/../bash/link.sh"
echo "=== Ghostty — terminal config and themes → ~/.config/ghostty ==="

link "$(pwd)/config" ~/.config/ghostty/config \
  "Ghostty terminal appearance and behavior settings"

link "$(pwd)/themes" ~/.config/ghostty/themes \
  "Ghostty color themes (light/dark)"
