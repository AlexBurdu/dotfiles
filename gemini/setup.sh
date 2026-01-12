#!/usr/bin/env bash
# This script symlinks configuration files from this directory to ~/.gemini
# It also merges JSON configuration files.

set -euo pipefail

# Check for jq
if ! command -v jq &> /dev/null; then
    echo "jq could not be found. Please install jq to continue."
    exit 1
fi

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
TARGET_DIR="$HOME/.gemini"
BACKUP_DIR="$HOME/.gemini.bak"

# Function to merge JSON files
merge_json() {
    source_file="$1"
    target_file="$2"
    filename=$(basename "$source_file")

    echo "Processing $filename..."
    if [ -f "$target_file" ]; then
        echo "Merging $filename into $target_file..."
        # Use jq to merge the json files. The values from the source file will override the ones in the target file.
        jq -s '.[0] + .[1]' "$target_file" "$source_file" > "$target_file.tmp" && mv "$target_file.tmp" "$target_file"
    else
        echo "Creating $target_file..."
        cp "$source_file" "$target_file"
    fi
}

# Backup existing config
if [ -d "$TARGET_DIR" ] || [ -f "$TARGET_DIR" ]; then
    echo "Backing up existing $TARGET_DIR to $BACKUP_DIR..."
    rm -rf "$BACKUP_DIR"
    cp -a "$TARGET_DIR" "$BACKUP_DIR"
    echo "Backup complete."
fi

# Create target directory
mkdir -p "$TARGET_DIR"

echo "Creating symlinks and merging settings in $TARGET_DIR..."
# Loop over files in the script's directory.
for file in "$SCRIPT_DIR"/*; do
    # Make sure it's a file
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        # Skip this setup script
        if [ "$filename" = "setup.sh" ]; then
            continue
        fi

        # Handle JSON files
        if [[ "$filename" == *.json ]]; then
            read -p "For $filename, do you want to (m)erge, sym(l)ink, or (s)kip? [m/l/s] " -n 1 -r
            echo
            case $REPLY in
                [Mm]*)
                    merge_json "$file" "$TARGET_DIR/$filename"
                    ;;
                [Ll]*)
                    target_symlink="$TARGET_DIR/$filename"
                    if [ -e "$target_symlink" ] || [ -L "$target_symlink" ]; then
                        read -p "Overwrite $target_symlink? (y/n) " -n 1 -r
                        echo
                        if [[ $REPLY =~ ^[Yy]$ ]]; then
                            ln -sf "$file" "$target_symlink"
                        fi
                    else
                        ln -s "$file" "$target_symlink"
                    fi
                    ;;
                [Ss]*)
                    echo "Skipping $filename."
                    ;;
                *)
                    echo "Invalid option. Skipping $filename."
                    ;;
            esac
            continue
        fi

        # Handle other files (symlinking)
        target_symlink="$TARGET_DIR/$filename"
        if [ -e "$target_symlink" ] || [ -L "$target_symlink" ]; then
            read -p "Overwrite $target_symlink? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                ln -sf "$file" "$target_symlink"
            fi
        else
            ln -s "$file" "$target_symlink"
        fi
    fi
done

echo "Setup complete."