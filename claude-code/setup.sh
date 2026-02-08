#!/usr/bin/env bash

mkdir -p ~/.claude

rm -rf ~/.claude/settings.json
ln -s "$(pwd)/settings.json" ~/.claude/settings.json

rm -rf ~/.claude/hooks
ln -s "$(pwd)/hooks" ~/.claude/hooks

rm -f ~/.claude/CLAUDE.md
ln -s "$(pwd)/CLAUDE.md" ~/.claude/CLAUDE.md

echo "Claude Code configuration installed."
