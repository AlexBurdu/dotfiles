#!/usr/bin/env bash

rm -rf ~/.config/Code/User/keybindings.json
rm -rf ~/.config/Code/User/settings.json

ln -s $(pwd)/keybindings.json ~/.config/Code/User/keybindings.json
ln -s $(pwd)/settings.json ~/.config/Code/User/settings.json

