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

# Prompt the user before symlinking the lazy-lock.json file
echo "Symlink nvim/lazy-lock.json? (y/n)"
read -r response
if [ "$response" = "y" ]; then
  rm -rf "$config_dir/lazy-lock.json"
  ln -s $(pwd)/lazy-lock.json "$config_dir/lazy-lock.json"
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
  response="n"
  if [ "$file" = "$(pwd)/lua/keymap/init.lua" ]; then
    response="y"
  else
    echo "Symlink $file? (y/n)"
    read -r response
  fi
  if [ "$response" = "y" ]; then
    rm -rf "$config_dir/lua/keymap/$(basename $file)"
    ln -s $file "$config_dir/lua/keymap/$(basename $file)"
  fi
done

# Plugins that are loaded dynamically. 
# We only symlink the lazy_nvim.lua file and prompt the user before symlink-ing
# any of any of the plugins.
mkdir -p "$config_dir/lua/plugins"
rm -rf ~/.config/nvim/lua/lazy_nvim.lua
ln -s "$(pwd)/lua/lazy_nvim.lua"   "$config_dir/lua/lazy_nvim.lua"
for file in $(pwd)/lua/plugins/*; do
  echo "Symlink $file? (y/n)"
  read -r response
  if [ "$response" = "y" ]; then
    rm -rf ~/.config/nvim/lua/plugins/$(basename $file)
    ln -s $file ~/.config/nvim/lua/plugins/$(basename $file)
  fi
done

