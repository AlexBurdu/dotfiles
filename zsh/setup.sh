#!/usr/bin/env bash

# Install zoxide (smarter cd that tracks frequently used directories)
echo ""
echo "zoxide is a smarter 'cd' command that learns your habits."
echo "It lets you jump to frequently used directories with 'z <partial-name>'."
echo "Example: 'z dot' could jump to ~/dotfiles"
echo ""
echo "Install zoxide? (y/n)"
read -r response
if [ "$response" = "y" ]; then
  if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install zoxide
  elif command -v apt &> /dev/null; then
    sudo apt install zoxide
  elif command -v dnf &> /dev/null; then
    sudo dnf install zoxide
  elif command -v pacman &> /dev/null; then
    sudo pacman -S zoxide
  else
    echo "Could not detect package manager. Install zoxide manually: https://github.com/ajeetdsouza/zoxide#installation"
  fi
fi

# Clone themes & plugins
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
git clone --depth=1 https://github.com/marlonrichert/zsh-autocomplete.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autocomplete
git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-autosuggestions
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install

rm -rf ~/.zshrc
echo "Do you want to copy or symlink ~/.zshrc? (c/s)"
read -r response
if [ "$response" = "c" ]; then
  cp $(pwd)/zshrc ~/.zshrc
elif [ "$response" = "s" ]; then
  ln -s $(pwd)/zshrc ~/.zshrc
fi
