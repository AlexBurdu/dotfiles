#!/usr/bin/env bash
# Generates and merges Gemini CLI configuration files
# from this directory into ~/.gemini.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../bash/link.sh"
source "$SCRIPT_DIR/../bash/json_merge.sh"
echo "=== Gemini CLI — settings and instructions → ~/.gemini ==="

# Check for jq
if ! command -v jq &> /dev/null; then
  echo "jq is required for JSON merging. Install it first."
  exit 1
fi

TARGET_DIR="$HOME/.gemini"
BACKUP_DIR="$HOME/.gemini.bak"

# Backup existing config
if [ -d "$TARGET_DIR" ]; then
  if [ -L "$BACKUP_DIR" ]; then
    echo "Error: $BACKUP_DIR is a symlink, refusing to overwrite"
    exit 1
  fi
  echo "Backing up existing $TARGET_DIR to $BACKUP_DIR..."
  rm -rf "$BACKUP_DIR"
  cp -a "$TARGET_DIR" "$BACKUP_DIR"
  echo "Backup complete."
fi

# Create target directory
mkdir -p "$TARGET_DIR"

# Build settings: start with base, then prompt for each hook group
result=$(jq . "$SCRIPT_DIR/settings.json")

for hook_file in "$SCRIPT_DIR"/hooks/*.json; do
  [ -f "$hook_file" ] || continue
  desc=$(jq -r '._description' "$hook_file")
  echo ""
  read -rp "Install hooks: ${desc}? (Y/n) " ans
  echo ""
  if [[ "$ans" != "n" ]]; then
    hooks_json=$(jq 'del(._description) | .hooks' "$hook_file")
    result=$(echo "$result" | jq --argjson new "$hooks_json" '
      reduce ($new | keys[]) as $event (.;
        .hooks[$event] = (.hooks[$event] // []) + $new[$event]
      )
    ')
  fi
done

for mcp_file in "$SCRIPT_DIR"/mcp/*.json; do
  [ -f "$mcp_file" ] || continue
  desc=$(jq -r '._description' "$mcp_file")
  echo ""
  read -rp "Install MCP server: ${desc}? (Y/n) " ans
  echo ""
  if [[ "$ans" != "n" ]]; then
    mcp_json=$(jq 'del(._description) | .mcpServers' "$mcp_file")
    result=$(echo "$result" | jq --argjson new "$mcp_json" '
      .mcpServers = (.mcpServers // {}) + $new
    ')
  fi
done

# Write generated settings to a temp file, then merge into target
tmpfile=$(mktemp "${TMPDIR:-/tmp}/gemini-settings.XXXXXX.json")
echo "$result" | jq . > "$tmpfile"
merge_json "$tmpfile" "$TARGET_DIR/settings.json" \
  "Gemini CLI settings (editor, vim mode, hooks, theme)"
rm -f "$tmpfile"

link "$(pwd)/GEMINI.md" "$TARGET_DIR/GEMINI.md" \
  "Global Gemini instructions (commit format, conventions)"

# Install top-level commands
mkdir -p "$TARGET_DIR/commands"
for cmd in commands/*.toml; do
  [ -f "$cmd" ] || continue
  name=$(basename "$cmd")
  # Extract description from TOML
  desc=$(grep '^description' "$cmd" | head -1 | sed 's/^description *= *"//;s/"$//')
  link "$(pwd)/$cmd" "$TARGET_DIR/commands/$name" \
    "/${name%.toml} — $desc"
done

# Install command groups
for group in commands/*/; do
  [ -d "$group" ] || continue
  group_name=$(basename "$group")
  echo ""
  read -rp "Install $group_name commands? (Y/n) " ans
  echo ""
  if [[ "$ans" != "n" ]]; then
    for cmd in "$group"*; do
      name=$(basename "$cmd")
      link "$(pwd)/$cmd" \
        "$TARGET_DIR/commands/$group_name/${name}" \
        "Command /$group_name:${name%.toml}"
    done
  fi
done

echo "Gemini CLI setup complete."
