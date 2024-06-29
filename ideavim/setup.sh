#!/usr/bin/env bash
CONFIG_DIR=~/.config/ideavim

rm ~/.ideavimrc
rm -rf ~/.config/ideavim.bak
cp -R ~/.config/ideavim ~/.config/ideavim.bak

mkdir -p $CONFIG_DIR
# loop through all *.vim files in the current directory
for file in $(pwd)/*.vim; do
  response="n"
  echo $file
  # check if symlink already exists and if it is a symlink, not a regular file
  # if it exists, prompt the user to overwrite it
  if [ -L "$CONFIG_DIR/$(basename $file)" ]; then
    echo "Symlink already exists: $CONFIG_DIR/$(basename $file)"
    echo "Do you want to overwrite it? (y/n)"
    read -r response
  # Skip prompting for the ideavimrc.vim file
  elif [ "$file" = "$(pwd)/ideavimrc.vim" ]; then
    response="y"
  else
    echo "Symlink $file? (y/n)"
    read -r response
  fi
  if [ "$response" = "y" ]; then
    rm -rf "$CONFIG_DIR/$(basename $file)"
    ln -s $file "$CONFIG_DIR/$(basename $file)"
  fi
done

ln -s ~/.config/ideavim/ideavimrc.vim ~/.ideavimrc
