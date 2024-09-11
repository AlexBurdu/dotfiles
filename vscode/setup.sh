#!/usr/bin/env bash
# Locations are different for Linux vs MacOS
CONFIG_DIR=~/.config/Code/User
if [[ "$OSTYPE" == "darwin"* ]]; then
  CONFIG_DIR=~/Library/Application\ Support/Code/User
fi

# Recursively create directories if they don't exist
mkdir -p "$CONFIG_DIR"

rm -rf "${CONFIG_DIR}/keybindings.json"
rm -rf "${CONFIG_DIR}/settings.json"

ln -s $(pwd)/keybindings.json "${CONFIG_DIR}/keybindings.json"
ln -s $(pwd)/settings.json "${CONFIG_DIR}/settings.json"

