#!/usr/bin/env bash
# Master setup — runs setup.sh in each subdirectory.
# Prompts before each one so you can skip what you don't need.
set -euo pipefail

root_dir=$(pwd)

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
