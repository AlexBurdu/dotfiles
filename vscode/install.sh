#!/usr/bin/env bash
# macOS preferences for the vscode module.
#
# Run by the root setup.sh after vscode/manifest.sh has merged, as a
# separate program.  --doctor never runs it.
set -euo pipefail

[[ "$OSTYPE" == darwin* ]] || exit 0

# macOS turns a quick double Space into ". " by asking the app to
# replace the previous character, not by sending a second Space.  VS
# Code passes that on as replacePreviousChar, which VSCodeVim ignores in
# Normal mode, so the second Space of a fast `Space Space` chord is
# lost.  Turned off for VS Code alone; other apps keep the period.
#
# The domain is the plist's path rather than its bundle id, so a run
# with a sandboxed HOME writes the sandbox's copy, never the real one.
prefs="$HOME/Library/Preferences/com.microsoft.VSCode"
key=NSAutomaticPeriodSubstitutionEnabled

echo ""
if [ "$(defaults read "$prefs" "$key" 2>/dev/null)" = "0" ]; then
  echo "  Double-space period is already off for VS Code."
else
  defaults write "$prefs" "$key" -bool false
  echo "  Turned off double-space period for VS Code; it applies the"
  echo "  next time VS Code starts."
fi
