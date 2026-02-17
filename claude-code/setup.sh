#!/usr/bin/env bash
# Symlinks Claude Code settings and global instructions into ~/.claude.
set -euo pipefail

if [[ -n "${CLAUDECODE:-}" ]]; then
  echo "Error: This script cannot run inside a Claude Code session."
  echo "Run it from a regular shell:  ./claude-code/setup.sh"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../bash/link.sh"
echo "=== Claude Code — settings, instructions → ~/.claude ==="

# Backup existing config
if [ -d ~/.claude ]; then
  if [ -L ~/.claude.bak ]; then
    echo "Error: ~/.claude.bak is a symlink, refusing to overwrite"
    exit 1
  fi
  echo "Backing up existing ~/.claude to ~/.claude.bak..."
  rm -rf ~/.claude.bak
  cp -a ~/.claude ~/.claude.bak
  echo "Backup complete."
fi

# Create target directory
mkdir -p ~/.claude

# Symlink settings and global instructions
link "$(pwd)/settings.json" ~/.claude/settings.json \
  "Claude Code global settings (permissions, formatters, linters)"

link "$(pwd)/CLAUDE.md" ~/.claude/CLAUDE.md \
  "Global Claude Code instructions (commit format, conventions)"

# Install top-level skills
mkdir -p ~/.claude/skills
for skill in skills/*/SKILL.md; do
  [ -f "$skill" ] || continue
  skill_dir=$(dirname "$skill")
  name=$(basename "$skill_dir")
  desc=$(sed -n '/^description:/{ s/^description: *//; p; q; }' "$skill")
  link "$(pwd)/$skill_dir" ~/.claude/skills/"$name" \
    "/$name — $desc"
done

# Install skill groups
for group_dir in skills/*/; do
  [ -d "$group_dir" ] || continue
  # Skip top-level skills (already handled above)
  [ -f "$group_dir/SKILL.md" ] && continue
  group_name=$(basename "$group_dir")
  echo ""
  read -rp "Install $group_name skills? (Y/n) " ans
  echo ""
  if [[ "$ans" != "n" ]]; then
    for skill in "$group_dir"*/SKILL.md; do
      [ -f "$skill" ] || continue
      skill_dir=$(dirname "$skill")
      name=$(basename "$skill_dir")
      desc=$(sed -n '/^description:/{ s/^description: *//; p; q; }' "$skill")
      link "$(pwd)/$skill_dir" ~/.claude/skills/"$group_name"-"$name" \
        "/$group_name-$name — $desc"
    done
  fi
done

# Install MCP servers (user scope, available across all projects)
for mcp_file in "$SCRIPT_DIR"/mcp/*.json; do
  [ -f "$mcp_file" ] || continue
  name=$(basename "${mcp_file%.json}")
  desc=$(jq -r '._description' "$mcp_file")
  echo ""
  read -rp "Install MCP server: ${desc}? (Y/n) " ans
  echo ""
  if [[ "$ans" != "n" ]]; then
    cmd=$(jq -r '.command' "$mcp_file")
    mapfile -t args_array < <(jq -r '.args[]' "$mcp_file")
    claude mcp add --scope user "$name" -- "$cmd" "${args_array[@]}"
  fi
done
