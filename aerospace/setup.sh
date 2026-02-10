#!/usr/bin/env bash
# Symlinks AeroSpace tiling window manager config into ~/.config/aerospace.
set -euo pipefail
source "$(dirname "$0")/../bash/link.sh"
echo "=== AeroSpace — tiling window manager config → ~/.config/aerospace ==="

link "$(pwd)/aerospace.toml" ~/.config/aerospace/aerospace.toml \
  "AeroSpace tiling window manager configuration"
