#!/usr/bin/env bash
# Master setup — runs setup.sh in each subdirectory.
# Prompts before each one so you can skip what you don't need.
set -euo pipefail

root_dir=$(pwd)

# Install the repo's git hooks first, so the guard against committing
# machine-specific paths and non-personal identities is active before anything
# else runs. core.hooksPath is per-clone, so every machine needs this once.
if [ -d "$root_dir/.git" ] || git -C "$root_dir" rev-parse --git-dir >/dev/null 2>&1; then
  git -C "$root_dir" config core.hooksPath .githooks
  echo "Git hooks enabled (core.hooksPath = .githooks)."
  if [ ! -f "$root_dir/.githooks/blocked-terms" ]; then
    cp "$root_dir/.githooks/blocked-terms.example" "$root_dir/.githooks/blocked-terms"
    echo "Seeded .githooks/blocked-terms — edit it to list names to keep out of this repo."
  fi
fi

# Find all setup.sh files in subdirectories
for setup in */setup.sh; do
  dir=$(dirname "$setup")
  echo ""
  read -rp "Run $dir/setup.sh? (Y/n) " ans
  echo ""
  if [[ "$ans" != "n" ]]; then
    cd "$dir"
    bash setup.sh
    cd "$root_dir"
  fi
done

echo ""
echo "All selected setup scripts have been run."
