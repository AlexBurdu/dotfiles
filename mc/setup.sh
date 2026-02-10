#!/usr/bin/env bash
# Symlinks Midnight Commander config directory into ~/.config/mc
# and updates file handler paths in mc.ext.ini.
set -euo pipefail
source "$(dirname "$0")/../bash/link.sh"
echo "=== Midnight Commander — file manager config → ~/.config/mc ==="

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MC_CONFIG=~/.config/mc

link "$SCRIPT_DIR" "$MC_CONFIG" \
  "Midnight Commander config directory (panels, keybindings, file handlers)"

# Update mc.ext.ini to use open-file.sh for all handlers
update_handlers() {
  local handlers_ini="$SCRIPT_DIR/handlers.ini"
  local ext_ini="$SCRIPT_DIR/mc.ext.ini"

  [ ! -f "$handlers_ini" ] && return
  [ ! -f "$ext_ini" ] && return

  # Extract handler types from handlers.ini (section names, excluding 'default')
  local types
  types=$(grep '^\[' "$handlers_ini" | tr -d '[]' | grep -v '^default$')

  # Escape sed metacharacters in paths.
  local mc_escaped
  mc_escaped=$(printf '%s' "$MC_CONFIG" | sed 's/[|&/\]/\\&/g')

  for type in $types; do
    # Type names come from handlers.ini section headers —
    # validate they are safe alphanumeric identifiers.
    if ! printf '%s' "$type" | grep -qE '^[a-zA-Z0-9_-]+$'; then
      echo "Skipping invalid handler type: $type" >&2
      continue
    fi

    local open_cmd="$mc_escaped/open-file.sh $type %f"
    # Try [Include/TYPE] section first (e.g., [Include/image])
    if grep -q "^\[Include/$type\]" "$ext_ini"; then
      sed -i'' -e "/^\[Include\/$type\]/,/^\[/{
        s|^Open=.*|Open=$open_cmd|
        s|^View=.*|View=$open_cmd|
      }" "$ext_ini"
    # Try direct [TYPE] section (e.g., [pdf])
    elif grep -q "^\[$type\]" "$ext_ini"; then
      sed -i'' -e "/^\[$type\]/,/^\[/{
        s|^Open=.*|Open=$open_cmd|
        s|^View=.*|View=$open_cmd|
      }" "$ext_ini"
    fi
  done

  # Update [Default] section for fallback handling
  if grep -q "^\[Default\]" "$ext_ini"; then
    sed -i'' -e "/^\[Default\]/,/^\[/{
      s|^Open=.*|Open=$mc_escaped/open-file.sh default %f|
    }" "$ext_ini"
  fi

  # Clean up sed backup file on macOS
  rm -f "$ext_ini-e"
}

update_handlers
echo "Midnight Commander setup complete."
