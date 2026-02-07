#!/usr/bin/env bash

mkdir -p ~/.claude

rm -rf ~/.claude/settings.json
ln -s "$(pwd)/settings.json" ~/.claude/settings.json

rm -rf ~/.claude/hooks
ln -s "$(pwd)/hooks" ~/.claude/hooks

echo "Claude Code configuration installed."
