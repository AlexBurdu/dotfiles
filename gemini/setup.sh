#!/usr/bin/env bash
# Symlinks and merges Gemini CLI configuration files
# from this directory into ~/.gemini.
set -euo pipefail
source "$(dirname "$0")/../bash/link.sh"
source "$(dirname "$0")/../bash/json_merge.sh"
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

# Merge settings (deep merge preserves existing keys)
merge_json "$(pwd)/settings.json" "$TARGET_DIR/settings.json" \
  "Gemini CLI settings (editor, vim mode, checkpointing, UI theme)"

link "$(pwd)/GEMINI.md" "$TARGET_DIR/GEMINI.md" \
  "Global Gemini instructions (commit format, conventions)"

# Install command groups
mkdir -p "$TARGET_DIR/commands"
for group in commands/*/; do
  group_name=$(basename "$group")
  echo ""
  read -rp "Install $group_name commands? (y/n) " ans
  if [[ "$ans" == "y" ]]; then
    for cmd in "$group"*; do
      name=$(basename "$cmd")
      link "$(pwd)/$cmd" \
        "$TARGET_DIR/commands/$group_name/${name}" \
        "Command /$group_name:${name%.toml}"
    done
  fi
done

echo "Gemini CLI setup complete."
