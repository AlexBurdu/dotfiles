#!/usr/bin/env bash
# Builds ~/.config/mc as a real directory: static config is symlinked back to
# this repo, generated and runtime files are local copies.
#
# ~/.config/mc used to be a symlink to this directory, which meant Midnight
# Commander wrote its runtime state (ini, panels.ini) straight into the working
# tree, and setup.sh rewrote the tracked mc.ext.ini with an absolute path that
# recorded whichever machine last ran it. Generating into the target instead
# keeps the repo machine-independent.
set -euo pipefail
source "$(dirname "$0")/../bash/link.sh"
echo "=== Midnight Commander — file manager config → ~/.config/mc ==="

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MC_CONFIG="$HOME/.config/mc"

# Migrate the old whole-directory symlink.
if [ -L "$MC_CONFIG" ]; then
  echo "~/.config/mc is a symlink to $(readlink "$MC_CONFIG"); replacing it with a real directory."
  rm "$MC_CONFIG"
fi
mkdir -p "$MC_CONFIG"

# Static config: symlinked, so edits in the repo take effect immediately.
link "$SCRIPT_DIR/handlers.ini" "$MC_CONFIG/handlers.ini" \
  "Midnight Commander file-type handlers (which command opens which type)"
link "$SCRIPT_DIR/open-file.sh" "$MC_CONFIG/open-file.sh" \
  "Midnight Commander cross-platform open helper"
link "$SCRIPT_DIR/mc.keymap" "$MC_CONFIG/mc.keymap" \
  "Midnight Commander keybindings"

# Runtime state: seeded once from the template, then owned by MC. Never linked
# back to the repo — MC rewrites ini on exit, and set-themes.sh seds the skin
# into it on every appearance change.
if [ ! -f "$MC_CONFIG/ini" ]; then
  cp "$SCRIPT_DIR/ini.template" "$MC_CONFIG/ini"
  echo "Seeded ~/.config/mc/ini from ini.template."
else
  echo "Keeping existing ~/.config/mc/ini (delete it to reseed from ini.template)."
fi

# Generated: the tracked mc.ext.ini carries a @MC_CONFIG@ placeholder; the copy
# in ~/.config/mc gets the real path. MC runs handler lines through /bin/sh, but
# it does not expand ~ or $HOME in them, so the path has to be resolved here.
generate_ext_ini() {
  local handlers_ini="$SCRIPT_DIR/handlers.ini"
  local src="$SCRIPT_DIR/mc.ext.ini"
  local ext_ini="$MC_CONFIG/mc.ext.ini"

  [ ! -f "$handlers_ini" ] && return
  [ ! -f "$src" ] && return

  # Escape sed metacharacters in the destination path.
  local mc_escaped
  mc_escaped=$(printf '%s' "$MC_CONFIG" | sed 's/[|&/\]/\\&/g')

  sed -e "s|@MC_CONFIG@|$mc_escaped|g" "$src" > "$ext_ini"

  # Extract handler types from handlers.ini (section names, excluding 'default')
  local types
  types=$(grep '^\[' "$handlers_ini" | tr -d '[]' | grep -v '^default$')

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
  echo "Generated ~/.config/mc/mc.ext.ini."
}

generate_ext_ini
echo "Midnight Commander setup complete."
