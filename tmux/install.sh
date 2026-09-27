#!/usr/bin/env bash
# Plugin manager for the tmux module.
#
# Run by the root setup.sh after tmux/manifest.sh has linked, as a
# separate program.  --doctor never runs it.
set -euo pipefail

# shellcheck source=bash/prompt.sh
source "${DOTFILES_LIB:?run this through the root setup.sh}/prompt.sh"

if [ ! -d ~/.tmux/plugins/tpm ]; then
  echo ""
  echo "  TPM (Tmux Plugin Manager) is not installed. It manages tmux"
  echo "  plugins like catppuccin and tmux-pilot."
  if confirm "Install TPM?"; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  fi
fi

if [ -x ~/.tmux/plugins/tpm/bin/install_plugins ]; then
  echo ""
  if confirm "Install/update tmux plugins?"; then
    ~/.tmux/plugins/tpm/bin/install_plugins
    ~/.tmux/plugins/tpm/bin/update_plugins all
  fi
fi
