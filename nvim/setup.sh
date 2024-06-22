#!/usr/bin/env bash

# Backup existing config
cp -r ~/.config/nvim ~/.config/nvim.bak

mkdir ~/.config/nvim
mkdir ~/.config/nvim/lua

# Symlink individual files and directories under lua
rm  -rf ~/.config/nvim/lua/color
ln -s $(pwd)/lua/color ~/.config/nvim/lua/color

rm -rf ~/.config/nvim/lua/copilot
ln -s $(pwd)/lua/copilot ~/.config/nvim/lua/copilot

rm -rf ~/.config/nvim/lua/options
ln -s $(pwd)/lua/options ~/.config/nvim/lua/options

rm -rf ~/.config/nvim/lua/keymap.lua
ln -s $(pwd)/lua/keymap.lua ~/.config/nvim/lua/keymap.lua

rm -rf ~/.config/nvim/lua/keymap.vim
ln -s $(pwd)/lua/keymap.vim ~/.config/nvim/lua/keymap.vim

mkdir ~/.config/nvim/lua/plugins
rm -rf ~/.config/nvim/lua/plugins/init.lua
ln -s $(pwd)/lua/plugins/init.lua ~/.config/nvim/lua/plugins/init.lua

# Just copy the init.lua instead of symlink-ing it so that it can be customized for local usage
# cp $(pwd)/init.lua ~/.config/nvim/init.lua
