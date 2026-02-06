#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MC_CONFIG=~/.config/mc

# Backup existing mc config
rm -rf "$MC_CONFIG.bak"
[ -e "$MC_CONFIG" ] && mv "$MC_CONFIG" "$MC_CONFIG.bak"

# Create a symlink to the mc config
ln -s "$SCRIPT_DIR" "$MC_CONFIG"

# Update mc.ext.ini to use open-file.sh for all handlers defined in handlers.ini
update_handlers() {
    local handlers_ini="$SCRIPT_DIR/handlers.ini"
    local ext_ini="$SCRIPT_DIR/mc.ext.ini"

    [ ! -f "$handlers_ini" ] && return
    [ ! -f "$ext_ini" ] && return

    # Extract handler types from handlers.ini (section names, excluding 'default')
    local types=$(grep '^\[' "$handlers_ini" | tr -d '[]' | grep -v '^default$')

    for type in $types; do
        # Try [Include/TYPE] section first (e.g., [Include/image])
        if grep -q "^\[Include/$type\]" "$ext_ini"; then
            sed -i'' -e "/^\[Include\/$type\]/,/^\[/{
                s|^Open=.*|Open=$MC_CONFIG/open-file.sh $type %f|
                s|^View=.*|View=$MC_CONFIG/open-file.sh $type %f|
            }" "$ext_ini"
            echo "Updated handler: [Include/$type]"
        # Try direct [TYPE] section (e.g., [pdf])
        elif grep -q "^\[$type\]" "$ext_ini"; then
            sed -i'' -e "/^\[$type\]/,/^\[/{
                s|^Open=.*|Open=$MC_CONFIG/open-file.sh $type %f|
                s|^View=.*|View=$MC_CONFIG/open-file.sh $type %f|
            }" "$ext_ini"
            echo "Updated handler: [$type]"
        else
            echo "Warning: No section found for handler '$type'"
        fi
    done

    # Update [Default] section for fallback handling
    if grep -q "^\[Default\]" "$ext_ini"; then
        sed -i'' -e "/^\[Default\]/,/^\[/{
            s|^Open=.*|Open=$MC_CONFIG/open-file.sh default %f|
        }" "$ext_ini"
        echo "Updated handler: [Default]"
    fi

    # Clean up sed backup file on macOS
    rm -f "$ext_ini-e"
}

update_handlers

echo "Midnight Commander config linked to $SCRIPT_DIR"
