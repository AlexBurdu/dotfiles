#!/usr/bin/env bash
# Script that iterates through all directories looking for a setup.sh file to run from those directories.

root_dir=$(pwd)

# Find all setup.sh files in other directories than the current one.
setup_files=$(find . -name "setup.sh" -not -path "./setup.sh")

for setup in $setup_files; do
  echo "Running setup.sh in $(dirname $setup)"
  cd "$(dirname $setup)"
  bash setup.sh
  cd $root_dir
done

echo "All setup.sh files have been run."
