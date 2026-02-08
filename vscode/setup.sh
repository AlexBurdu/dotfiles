#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Locations are different for Linux vs MacOS
CONFIG_DIR=~/.config/Code/User
if [[ "$OSTYPE" == "darwin"* ]]; then
  CONFIG_DIR=~/Library/Application\ Support/Code/User
fi

# Recursively create directories if they don't exist
mkdir -p "$CONFIG_DIR"

rm -rf "${CONFIG_DIR}/keybindings.json"
rm -rf "${CONFIG_DIR}/settings.json"

ln -s "$SCRIPT_DIR/keybindings.json" "${CONFIG_DIR}/keybindings.json"
ln -s "$SCRIPT_DIR/settings.json" "${CONFIG_DIR}/settings.json"

