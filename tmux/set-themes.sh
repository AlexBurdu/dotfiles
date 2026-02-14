#!/bin/bash
# Set theme for tmux, nvim, mc, and gemini based on OS dark/light mode
# Called from tmux.conf on reload

MODE_FILE=~/.local/share/tmux/mode

is_dark_mode() {
  # Manual override (e.g. for SSH where OS detection isn't available)
  if [ -f "$MODE_FILE" ]; then
    [ "$(cat "$MODE_FILE")" = "dark" ]
    return
  fi

  case "$(uname)" in
    Darwin)
      # macOS: returns "Dark" if dark mode, errors if light mode
      defaults read -g AppleInterfaceStyle 2>/dev/null | grep -q Dark
      ;;
    Linux)
      # GNOME/GTK: check color-scheme setting
      gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null \
        | grep -q dark
      ;;
  esac
}

# Always use mocha accent colors (both spellings for plugin compatibility)
tmux set -g @catppuccin_flavor "mocha"
tmux set -g @catppuccin_flavour "mocha"

if is_dark_mode; then
  # Dark theme
  tmux set -g @catppuccin_status_background "#000000"
  tmux set message-style "fg=#ffffff"
  tmux set message-command-style "fg=#ffffff"
  tmux set pane-border-style fg=grey
  tmux set window-style bg=#111111
  tmux set window-active-style bg=#000000

  sed -i'' -e 's/skin=.*/skin=nicedark/' ~/.config/mc/ini
  sed -i'' -e 's/"theme": ".*"/"theme": "Shades Of Purple"/' \
    ~/.gemini/settings.json 2>/dev/null

  nvim_theme=carbonfox
else
  # Light theme
  tmux set -g @catppuccin_status_background "#eff1f5"
  tmux set message-style "fg=white,bg=black"
  tmux set pane-border-style fg=black
  tmux set window-style bg=#e0e1e7
  tmux set window-active-style bg=#f0f1f7

  sed -i'' -e 's/skin=.*/skin=seasons-winter16M/' ~/.config/mc/ini
  sed -i'' -e 's/"theme": ".*"/"theme": "Google Code"/' \
    ~/.gemini/settings.json 2>/dev/null

  nvim_theme=dayfox
fi

# Save theme for reference (user-owned directory, not /tmp)
mkdir -p ~/.local/share/tmux
echo "$nvim_theme" > ~/.local/share/tmux/theme

# Sync nvim theme in all vim panes
for pane in $(tmux list-panes -a -F "#{pane_id}:#{pane_current_command}" \
  | grep -i vim | cut -d: -f1); do
  tmux send-keys -t "$pane" Escape ":colorscheme ${nvim_theme}" Enter
done
