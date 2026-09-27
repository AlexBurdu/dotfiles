# shellcheck shell=bash
platform mac linux
module "Zsh — plugins and zshrc"

link zshrc ~/.zshrc \
  "oh-my-zsh, powerlevel10k, vim-mode, fzf, aliases"

# Machine-specific shell config is not carried here: zshrc sources
# ~/.config/zsh/*.zsh, which an overlay drops files into.  See the
# Overlays section of ../README.md.
