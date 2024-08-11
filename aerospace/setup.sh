#!/usr/bin/env bash

rm -rf ~/.config/aerospace.aerospace.toml
mkdir -p ~/.config/aerospace
ln -s $(pwd)/aerospace.toml ~/.config/aerospace/aerospace.toml
