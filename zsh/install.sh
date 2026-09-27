#!/usr/bin/env bash
# Packages and plugins for the zsh module.
#
# Run by the root setup.sh after zsh/manifest.sh has linked, as a
# separate program.  --doctor never runs it.
set -euo pipefail

# shellcheck source=bash/prompt.sh
source "${DOTFILES_LIB:?run this through the root setup.sh}/prompt.sh"

custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# Every question in a run is asked by prompt.sh, so a tool that would
# ask its own -- a package manager's "continue?", fzf's installer -- is
# told the answer by flag instead.  The "yes" was given above it.

echo ""
if command -v zoxide >/dev/null 2>&1; then
  echo "  zoxide is already installed."
elif echo "  zoxide is a smarter 'cd' that learns your habits: 'z dot' jumps"
  echo "  to ~/dotfiles."
  confirm "Install zoxide?"; then
  if [[ "$OSTYPE" == darwin* ]]; then
    brew install zoxide
  elif command -v apt >/dev/null 2>&1; then
    sudo apt install -y zoxide
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y zoxide
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --noconfirm zoxide
  else
    echo "  No known package manager. Install zoxide by hand:"
    echo "    https://github.com/ajeetdsouza/zoxide#installation"
  fi
fi

echo ""
if confirm "Install/update zsh plugins?"; then
  # Already-cloned is the common case, and not an error worth stopping
  # the run for.
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    "$custom/themes/powerlevel10k" 2>/dev/null || true
  git clone --depth=1 https://github.com/marlonrichert/zsh-autocomplete.git \
    "$custom/plugins/zsh-autocomplete" 2>/dev/null || true
  git clone https://github.com/zsh-users/zsh-completions \
    "$custom/plugins/zsh-completions" 2>/dev/null || true
  git clone https://github.com/zsh-users/zsh-autosuggestions \
    "$custom/plugins/zsh-autosuggestions" 2>/dev/null || true
  git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf \
    2>/dev/null || true
  # The clone is allowed to fail (already present, no network), so the
  # installer has to be checked for rather than assumed.  Key bindings
  # and completion go in ~/.fzf.zsh, which zshrc sources; zshrc is this
  # repo's, so the installer must not edit it.
  if [ -x ~/.fzf/install ]; then
    ~/.fzf/install --key-bindings --completion --no-update-rc \
      --no-bash --no-fish
  fi
fi
