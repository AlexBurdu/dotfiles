#!/usr/bin/env bash
# Symlinks Terminator terminal emulator config into ~/.config/terminator.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../bash/link.sh"
echo "=== Terminator — terminal emulator config → ~/.config/terminator ==="

link "$SCRIPT_DIR/config" ~/.config/terminator/config \
  "Terminator terminal emulator configuration"
