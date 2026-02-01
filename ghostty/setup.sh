#!/usr/bin/env bash

CONFIG_DIR=~/.config/ghostty

mkdir -p "$CONFIG_DIR"

rm -rf "$CONFIG_DIR/config"
ln -s "$(pwd)/config" "$CONFIG_DIR/config"

rm -rf "$CONFIG_DIR/themes"
ln -s "$(pwd)/themes" "$CONFIG_DIR/themes"

echo "Ghostty configuration installed."
