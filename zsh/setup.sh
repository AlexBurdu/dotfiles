#!/usr/bin/env bash
# Clone themes & plugins
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
git clone --depth=1 https://github.com/marlonrichert/zsh-autocomplete.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autocomplete
git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-autosuggestions

rm -rf ~/.zshrc
echo "Do you want to copy or symlink ~/.zshrc? (c/s)"
read -r response
if [ "$response" = "c" ]; then
  cp $(pwd)/zshrc ~/.zshrc
elif [ "$response" = "s" ]; then
  ln -s $(pwd)/zshrc ~/.zshrc
fi
