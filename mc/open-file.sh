#!/usr/bin/env bash
#
# Cross-platform file opener for Midnight Commander
# Usage: open-file.sh <type> <file>
#
# Reads handlers.ini to determine the appropriate command for the current OS.

TYPE=$1
FILE=$2
CONF_DIR="$(dirname "$0")"
INI_FILE="$CONF_DIR/handlers.ini"

# Determine OS
[[ "$OSTYPE" == darwin* ]] && OS="macos" || OS="linux"

# Parse INI: get value for section and key
get_handler() {
    local section=$1
    awk -F= -v section="[$section]" -v key="$OS" '
        $0 == section { in_section=1; next }
        /^\[/ { in_section=0 }
        in_section && $1 ~ key { gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2; exit }
    ' "$INI_FILE"
}

# Get handler for type, fallback to default
HANDLER=$(get_handler "$TYPE")
[[ -z "$HANDLER" ]] && HANDLER=$(get_handler "default")

exec "$HANDLER" "$FILE"
