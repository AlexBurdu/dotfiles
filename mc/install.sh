#!/usr/bin/env bash
# Generated and seeded files for the mc module.
#
# Run by the root setup.sh after mc/manifest.sh has linked, as a
# separate program: it gets MODULE_DIR from the environment and none of
# the manifest vocabulary.  --doctor never runs it.
set -euo pipefail

mc_config=$HOME/.config/mc

# Runtime state: seeded once, then owned by MC.  Never linked back to
# the repo -- MC rewrites ini on exit, and set-themes.sh seds the skin
# into it on every appearance change.
if [ ! -f "$mc_config/ini" ]; then
  cp "$MODULE_DIR/ini.template" "$mc_config/ini"
  echo "  seeded $mc_config/ini from ini.template"
else
  echo "  keeping $mc_config/ini (delete it to reseed from ini.template)"
fi

# The tracked mc.ext.ini carries a @MC_CONFIG@ placeholder; the copy in
# ~/.config/mc gets the real path.  MC runs handler lines through
# /bin/sh but does not expand ~ or $HOME in them, so the path has to be
# resolved at setup time -- which is also why this file is generated
# rather than linked.
handlers_ini="$MODULE_DIR/handlers.ini"
src="$MODULE_DIR/mc.ext.ini"
ext_ini="$mc_config/mc.ext.ini"

if [ ! -f "$handlers_ini" ] || [ ! -f "$src" ]; then exit 0; fi

# Escape sed metacharacters in the destination path.
mc_escaped=$(printf '%s' "$mc_config" | sed 's/[|&/\]/\\&/g')
sed -e "s|@MC_CONFIG@|$mc_escaped|g" "$src" > "$ext_ini"

# Handler types are the section names in handlers.ini, minus 'default'.
types=$(grep '^\[' "$handlers_ini" | tr -d '[]' | grep -v '^default$')

for type in $types; do
  # Those names come from a file, so check they are safe identifiers
  # before they reach sed.
  if ! printf '%s' "$type" | grep -qE '^[a-zA-Z0-9_-]+$'; then
    echo "Skipping invalid handler type: $type" >&2
    continue
  fi
  open_cmd="$mc_escaped/open-file.sh $type %f"
  if grep -q "^\[Include/$type\]" "$ext_ini"; then
    sed -i'' -e "/^\[Include\/$type\]/,/^\[/{
      s|^Open=.*|Open=$open_cmd|
      s|^View=.*|View=$open_cmd|
    }" "$ext_ini"
  elif grep -q "^\[$type\]" "$ext_ini"; then
    sed -i'' -e "/^\[$type\]/,/^\[/{
      s|^Open=.*|Open=$open_cmd|
      s|^View=.*|View=$open_cmd|
    }" "$ext_ini"
  fi
done

if grep -q "^\[Default\]" "$ext_ini"; then
  sed -i'' -e "/^\[Default\]/,/^\[/{
    s|^Open=.*|Open=$mc_escaped/open-file.sh default %f|
  }" "$ext_ini"
fi

rm -f "$ext_ini-e"   # sed -i'' leaves this behind on macOS
echo "  generated $ext_ini"
