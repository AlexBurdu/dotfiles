#!/usr/bin/env bash
# Symlinks AeroSpace tiling window manager config into ~/.config/aerospace.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../bash/link.sh"
echo "=== AeroSpace — tiling window manager config → ~/.config/aerospace ==="

link "$SCRIPT_DIR/aerospace.toml" ~/.config/aerospace/aerospace.toml \
  "AeroSpace tiling window manager configuration"
