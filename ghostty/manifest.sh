# shellcheck shell=bash
platform mac linux
module "Ghostty — terminal config and themes"

link config ~/.config/ghostty/config \
  "Appearance and behaviour settings"
link themes ~/.config/ghostty/themes \
  "Colour themes (light/dark), added to by dropping a file in"
