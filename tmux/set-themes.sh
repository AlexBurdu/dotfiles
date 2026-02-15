#!/bin/bash
# Set theme for tmux, nvim, mc, and gemini based on OS dark/light mode
# Usage: set-themes.sh [init]
#   init  — full initialization (before TPM): clear stale vars, set all options
#   (none) — post-TPM: re-apply styles that catppuccin overrides

MODE_FILE=~/.local/share/tmux/mode

# Powerline glyphs as raw UTF-8 bytes (compatible with macOS bash 3.2)
LHC=$'\xee\x82\xb6'  # U+E0B6 left half-circle
RHC=$'\xee\x82\xb4'  # U+E0B4 right half-circle

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

# ── Full initialisation (before TPM) ────────────────────────────────
if [ "$1" = "init" ]; then

  # Clear stale catppuccin theme variables so the plugin re-applies
  # them for the current flavor (plugin uses -o, skipping vars already set)
  for o in $(tmux show -g 2>/dev/null \
    | grep -oE "^(@thm_|@_ctp_|@catppuccin_status_\S+_(fg|bg))[^ ]*"); do
    tmux set -gu "$o"
  done
  tmux set -gu @catppuccin_window_current_left_separator
  tmux set -gu @catppuccin_window_current_right_separator

  # ── Window styling (shared across modes) ──────────────────────────
  tmux set -g @catppuccin_window_status_style "custom"
  tmux set -g @catppuccin_window_number_position "right"
  tmux set -g @catppuccin_window_text " #W"
  tmux set -g @catppuccin_window_current_text " #W"
  tmux set -g @catppuccin_window_number "#I "
  tmux set -g @catppuccin_window_current_number "#[fg=#{@thm_fg}]#I "
  # Rounded caps (same as "rounded" preset)
  tmux set -g @catppuccin_window_left_separator \
    "#[fg=#{@_ctp_status_bg},reverse]${LHC}#[none]"
  tmux set -g @catppuccin_window_right_separator \
    "#[fg=#{@_ctp_status_bg},reverse]${RHC}#[none]"
  # Inactive: Powerline transition into number badge; Active: dot
  tmux set -g @catppuccin_window_middle_separator \
    " #[fg=#{@catppuccin_window_number_color}]${LHC}"
  tmux set -g @catppuccin_window_current_middle_separator " ●"
  # Inactive window colors (adapt via theme variables)
  tmux set -g @catppuccin_window_text_color "#{@thm_surface_0}"
  tmux set -g @catppuccin_window_number_color "#{@thm_overlay_2}"

  # ── Status module layout (shared) ─────────────────────────────────
  tmux set -g @catppuccin_status_left_separator "${LHC}"
  tmux set -g @catppuccin_status_right_separator "${RHC}"
  tmux set -g @catppuccin_status_fill "icon"
  tmux set -g @catppuccin_status_connect_separator "no"
  tmux set -g @catppuccin_directory_text " #{pane_current_path}"
  tmux set -g @catppuccin_status_directory_icon_fg "#{@thm_fg}"
  tmux set -g @catppuccin_status_session_icon_fg "#{@thm_fg}"

  # ── Mode-dependent options ────────────────────────────────────────
  if is_dark_mode; then
    tmux set -g @catppuccin_flavor "mocha"
    tmux set -g @catppuccin_flavour "mocha"
    tmux set -g @catppuccin_status_background "#000000"
    tmux set -g prompt-cursor-colour "#cdd6f4"
    tmux set -g pane-border-style fg=grey
    tmux set -g pane-active-border-style fg=blue
    tmux set -g window-style bg=#111111
    tmux set -g window-active-style bg=#000000
    # Active window pill
    tmux set -g @catppuccin_window_current_text_color "#89b4fa"
    tmux set -g @catppuccin_window_current_number_color "#89b4fa"
    # Status module colors
    tmux set -g @catppuccin_directory_color "#f5e0dc"
    tmux set -g @catppuccin_session_color \
      '#{?client_prefix,#{E:@thm_red},#a6e3a1}'
    tmux set -g @catppuccin_status_session_icon_fg "#000000"
    tmux set -g @catppuccin_status_directory_icon_fg "#000000"
    tmux set -g @catppuccin_status_session_text_fg "#ffffff"
    tmux set -g @catppuccin_status_directory_text_fg "#ffffff"
    # Active window: black text on blue pill
    tmux set -g @catppuccin_window_current_text " #[fg=#000000]#W"
    tmux set -g @catppuccin_window_current_number "#[fg=#000000]#I "

    sed -i'' -e 's/skin=.*/skin=nicedark/' ~/.config/mc/ini 2>/dev/null
    sed -i'' -e 's/"theme": ".*"/"theme": "Shades Of Purple"/' \
      ~/.gemini/settings.json 2>/dev/null

    resolved_mode=dark
  else
    tmux set -g @catppuccin_flavor "latte"
    tmux set -g @catppuccin_flavour "latte"
    tmux set -g @catppuccin_status_background "#eff1f5"
    tmux set -g prompt-cursor-colour "#4c4f69"
    tmux set -g pane-border-style fg=black
    tmux set -g pane-active-border-style fg=blue
    tmux set -g window-style bg=#e0e1e7
    tmux set -g window-active-style bg=#f0f1f7
    # Active window pill
    tmux set -g @catppuccin_window_current_text_color "#B0C9ED"
    tmux set -g @catppuccin_window_current_number_color "#B0C9ED"
    # Status module colors
    tmux set -g @catppuccin_directory_color "#F0C8D2"
    tmux set -g @catppuccin_session_color \
      '#{?client_prefix,#{E:@thm_red},#a6e3a1}'
    tmux set -g @catppuccin_status_session_icon_fg "#000000"
    tmux set -g @catppuccin_status_directory_icon_fg "#000000"
    tmux set -g @catppuccin_status_session_text_fg "#000000"
    tmux set -g @catppuccin_status_directory_text_fg "#000000"

    sed -i'' -e 's/skin=.*/skin=seasons-winter16M/' ~/.config/mc/ini 2>/dev/null
    sed -i'' -e 's/"theme": ".*"/"theme": "Google Code"/' \
      ~/.gemini/settings.json 2>/dev/null

    resolved_mode=light
  fi

  # Save theme for reference (user-owned directory, not /tmp)
  mkdir -p ~/.local/share/tmux
  echo "$resolved_mode" > ~/.local/share/tmux/theme

  # Map resolved mode to nvim colorscheme
  case "$resolved_mode" in dark) nvim_cs=carbonfox;; light) nvim_cs=dayfox;; esac

  # Sync nvim theme in all vim panes
  for pane in $(tmux list-panes -a -F "#{pane_id}:#{pane_current_command}" \
    | grep -i vim | cut -d: -f1); do
    tmux send-keys -t "$pane" Escape ":colorscheme ${nvim_cs}" Enter
  done

  # Sync Claude Code theme
  ~/.config/tmux/hooks/sync-claude-theme.sh
fi

# ── Styles that catppuccin overrides (always re-applied after TPM) ──
# Clear stale session-level overrides (from older configs that lacked -g)
tmux set -su message-style 2>/dev/null
tmux set -su message-command-style 2>/dev/null
if is_dark_mode; then
  tmux set -g message-style "fg=#000000,bg=#89b4fa"
  tmux set -g message-command-style "fg=white,bg=#313244"
  tmux set -g popup-style "bg=#000000,fg=#cdd6f4"
  tmux set -g popup-border-style "fg=#45475a"
else
  tmux set -g message-style "fg=black,bg=#B0C9ED"
  tmux set -g message-command-style "fg=black,bg=#ccd0da"
  tmux set -g popup-style "bg=#eff1f5,fg=#4c4f69"
  tmux set -g popup-border-style "fg=#9ca0b0"
fi
