#!/usr/bin/env bash
# Installs zsh plugins, symlinks zshrc into ~/.zshrc, and
# worktree functions into ~/.config/zsh.
set -euo pipefail
source "$(dirname "$0")/../bash/link.sh"
echo "=== Zsh — plugins, zshrc → ~/.zshrc, worktree functions → ~/.config/zsh ==="

# Install zoxide (smarter cd that tracks frequently used directories)
echo ""
echo "zoxide is a smarter 'cd' command that learns your habits."
echo "It lets you jump to frequently used directories with 'z <partial-name>'."
echo "Example: 'z dot' could jump to ~/dotfiles"
echo ""
read -rp "Install zoxide? (y/n) " response
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
echo ""
read -rp "Install/update zsh plugins (powerlevel10k, autocomplete, completions, autosuggestions, fzf)? (y/n) " response
if [ "$response" = "y" ]; then
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k 2>/dev/null || true
  git clone --depth=1 https://github.com/marlonrichert/zsh-autocomplete.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autocomplete 2>/dev/null || true
  git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions 2>/dev/null || true
  git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-autosuggestions 2>/dev/null || true
  git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf 2>/dev/null || true
  ~/.fzf/install
fi

echo ""
link "$(pwd)/zshrc" ~/.zshrc \
  "Zsh config (oh-my-zsh, powerlevel10k, vim-mode, fzf, aliases)"

link "$(pwd)/worktree.zsh" ~/.config/zsh/worktree.zsh \
  "Git worktree + agent launcher functions (wt-create, wt-launch, wt-list, wt-cleanup)"
