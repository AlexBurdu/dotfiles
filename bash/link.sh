#!/usr/bin/env bash
# Prompt-and-symlink helper for dotfiles setup scripts.
# Source this from any setup.sh:
#   source "$(dirname "$0")/../bash/link.sh"

# Show a description and prompt before creating a symlink.
# Creates parent directories as needed. Removes existing
# file/symlink at the destination before linking.
# Globals:
#   None
# Arguments:
#   $1 - source path (file or directory in the dotfiles repo)
#   $2 - destination path (where the symlink will be created)
#   $3 - human-readable description shown before the prompt
# Outputs:
#   Writes description and path mapping to stdout,
#   prompts for confirmation on stdin.
# Returns:
#   0 on success or if user declines.
link() {
  local src="$1" dst="$2" desc="$3"
  printf '%s\n  %s → %s\n' "$desc" "$src" "$dst"
  read -rp "Symlink? (y/n) " ans
  if [[ "$ans" == "y" ]]; then
    mkdir -p "$(dirname "$dst")"
    rm -rf "$dst"
    ln -s "$src" "$dst"
  fi
}
