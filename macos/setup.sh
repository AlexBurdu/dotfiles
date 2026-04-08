#!/usr/bin/env bash
source "$(dirname "$0")/../bash/link.sh"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

link "$SCRIPT_DIR/profile" ~/.profile "macOS login profile"
