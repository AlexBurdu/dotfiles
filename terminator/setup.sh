#!/usr/bin/env bash
# Symlinks Terminator terminal emulator config into ~/.config/terminator.
set -euo pipefail
source "$(dirname "$0")/../bash/link.sh"
echo "=== Terminator — terminal emulator config → ~/.config/terminator ==="

link "$(pwd)/config" ~/.config/terminator/config \
  "Terminator terminal emulator configuration"
