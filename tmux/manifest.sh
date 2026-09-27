# shellcheck shell=bash
platform mac linux
module "Tmux — config, theme switcher, agent hooks"

link tmux.conf ~/.config/tmux/tmux.conf \
  "Keybindings (prefix C-s), plugins, catppuccin theme"
link set-themes.sh ~/.config/tmux/set-themes.sh \
  "Theme switcher — syncs light/dark across apps from OS appearance"
link theme-picker.sh ~/.config/tmux/theme-picker.sh \
  "Theme picker popup (dark/light/auto)"
link hooks ~/.config/tmux/hooks \
  "Agent hooks — window naming, Claude Code theme sync"

