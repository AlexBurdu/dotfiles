#!/usr/bin/env bash
config_dir=~/.config/nvim

# Backup existing config
cp -r ~/.config/nvim ~/.config/nvim.bak

# Recursively create directories if they don't exist
mkdir -p "$config_dir/lua"

# Prompt the user before symlinking the init.lua file
echo "Symlink nvim/init.lua? (y/n)"
read -r response
if [ "$response" = "y" ]; then
  rm -rf "$config_dir/init.lua"
  ln -s $(pwd)/init.lua "$config_dir/init.lua"
fi

rm  -rf "$config_dir/lua/config"
ln -s $(pwd)/lua/config/ "$config_dir/lua/config"

# Symlink individual files and directories under lua
rm  -rf "$config_dir/lua/color"
ln -s $(pwd)/lua/color "$config_dir/lua/color"

rm  -rf "$config_dir/lua/options"
ln -s $(pwd)/lua/options "$config_dir/lua/options"

# Symlink files inside the keymap directory. Prompt the user for each file
# before symlinking it, with the exception of init.lua
mkdir -p "$config_dir/lua/keymap"
for file in $(pwd)/lua/keymap/*; do
  if [ "$file" = "$(pwd)/lua/keymap/init.lua" ]; then
    rm -rf "$config_dir/lua/keymap/$(basename $file)"
    ln -s $file "$config_dir/lua/keymap/$(basename $file)"
    continue
  fi
  echo "Symlink $file? (y/n)"
  read -r response
  if [ "$response" = "y" ]; then
    rm -rf "$config_dir/lua/keymap/$(basename $file)"
    ln -s $file "$config_dir/lua/keymap/$(basename $file)"
  fi
done

# plugins that are loaded dynamically. 
# We only symlink the init.lua file and prompt the user before symlink-ing
# any of any of the other ones.
mkdir ~/.config/nvim/lua/plugins
for file in $(pwd)/lua/plugins/*; do
  if [ "$file" = "$(pwd)/lua/plugins/init.lua" ]; then
    rm -rf ~/.config/nvim/lua/plugins/init.lua
    ln -s $file ~/.config/nvim/lua/plugins/$(basename $file)
    continue
  fi
  echo "Symlink $file? (y/n)"
  read -r response
  if [ "$response" = "y" ]; then
    ln -s $file ~/.config/nvim/lua/plugins/$(basename $file)
  fi
done

# Plug plugins that are loaded dynamically. 
# We only symlink the init.lua file and prompt the user before symlink-ing
# any of any of the other ones.
mkdir ~/.config/nvim/lua/plugins_plug
for file in $(pwd)/lua/plugins_plug/*; do
  if [ "$file" = "$(pwd)/lua/plugins_plug/init.lua" ]; then
    rm -rf ~/.config/nvim/lua/plugins_plug/init.lua
    ln -s $file ~/.config/nvim/lua/plugins_plug/$(basename $file)
    continue
  fi
  echo "Symlink $file? (y/n)"
  read -r response
  if [ "$response" = "y" ]; then
    ln -s $file ~/.config/nvim/lua/plugins_plug/$(basename $file)
  fi
done

