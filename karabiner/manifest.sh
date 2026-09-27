# shellcheck shell=bash
platform mac
module "Karabiner-Elements — keyboard remapping"

link karabiner.json ~/.config/karabiner/karabiner.json \
  "Remapping rules (Return=Ctrl on hold, LCmd=Backspace on tap)"
