#!/usr/bin/env bash
# Prompt-and-merge helper for JSON config files.
# Requires jq. Source this from any setup.sh:
#   source "$(dirname "$0")/../bash/json_merge.sh"

# Deep-merge a source JSON file into a destination JSON file.
# Shows a diff of what will change before prompting. Validates
# both files as valid JSON before merging. Uses jq recursive
# merge (source keys override target at all nesting levels,
# but unrelated keys in target are preserved).
# If the destination doesn't exist, copies the source instead.
# Globals:
#   None
# Arguments:
#   $1 - source JSON file (from dotfiles repo)
#   $2 - destination JSON file (installed config location)
#   $3 - human-readable description shown before the prompt
# Outputs:
#   Writes description, file paths, and a preview diff to
#   stdout. Prompts for confirmation on stdin.
# Returns:
#   0 on success or if user declines.
#   1 if source file is missing or either file is invalid JSON.
merge_json() {
  local src="$1" dst="$2" desc="$3"
  printf '%s\n  merge %s into %s\n' "$desc" "$src" "$dst"

  if [[ ! -f "$src" ]]; then
    echo "  Error: source file not found: $src"
    return 1
  fi

  # Validate source JSON
  if ! jq empty "$src" 2>/dev/null; then
    echo "  Error: invalid JSON in source: $src"
    return 1
  fi

  mkdir -p "$(dirname "$dst")"

  if [[ ! -f "$dst" ]]; then
    echo "  Destination does not exist — will copy source."
    read -rp "Copy? (y/n) " ans
    if [[ "$ans" == "y" ]]; then
      cp "$src" "$dst"
    fi
    return 0
  fi

  # Validate destination JSON
  if ! jq empty "$dst" 2>/dev/null; then
    echo "  Error: invalid JSON in destination: $dst"
    return 1
  fi

  # Preview: show what will change
  local merged
  merged=$(jq -s '.[0] * .[1]' "$dst" "$src") || {
    echo "  Error: merge failed"
    return 1
  }

  echo ""
  echo "  Changes:"
  diff --color=auto \
    <(jq --sort-keys . "$dst") \
    <(echo "$merged" | jq --sort-keys .) \
    | sed 's/^/    /' || true
  echo ""

  read -rp "Merge? (y/n) " ans
  if [[ "$ans" == "y" ]]; then
    echo "$merged" | jq . > "$dst.tmp" && mv "$dst.tmp" "$dst"
  fi
}
