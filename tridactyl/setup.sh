#!/usr/bin/env bash

CONFIG_DIR=~/.config/tridactyl

# Recursively create directories if they don't exist
mkdir -p "$CONFIG_DIR"

rm -rf $CONFIG_DIR/tridactylrc
ln -s $(pwd)/tridactylrc $CONFIG_DIR/tridactylrc
