#!/usr/bin/env bash
# The zoom-step extension, and macOS preferences, for the vscode module.
#
# Run by the root setup.sh after vscode/manifest.sh has merged, as a
# separate program.  --doctor never runs it.
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)

# zoom-step is packed into a .vsix and installed through VS Code's CLI,
# which registers it as an extension; a folder copied into
# ~/.vscode/extensions is not.  Reinstalled only when its files differ
# from the installed copy, whose package.json VS Code adds __metadata
# to.  A .vsix is a zip of the extension under extension/, beside a
# manifest that names it.
code=$(command -v code || true)
app_cli="/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
app_cli="$app_cli/code"
if [ -z "$code" ] && [ -x "$app_cli" ]; then code=$app_cli; fi
version=$(sed -n 's/^  "version": "\(.*\)",$/\1/p' \
  "$here/zoom-step/package.json")
installed="$HOME/.vscode/extensions/dotfiles.zoom-step-$version"
echo ""
if [ -z "$code" ]; then
  echo "  No VS Code CLI (code) found; zoom-step not installed."
elif cmp -s "$here/zoom-step/extension.js" "$installed/extension.js" \
  && [ -f "$installed/package.json" ] \
  && [ "$(jq -S . "$here/zoom-step/package.json")" \
    = "$(jq -S 'del(.__metadata)' "$installed/package.json")" ]; then
  echo "  zoom-step $version is already installed."
else
  pack=$(mktemp -d "${TMPDIR:-/tmp}/zoom-step.XXXXXX")
  trap 'rm -rf "$pack"' EXIT
  mkdir "$pack/extension"
  cp "$here/zoom-step/package.json" "$here/zoom-step/extension.js" \
    "$pack/extension/"
  cat > "$pack/[Content_Types].xml" <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension=".json" ContentType="application/json"/>
  <Default Extension=".js" ContentType="application/javascript"/>
  <Default Extension=".vsixmanifest" ContentType="text/xml"/>
</Types>
XML
  cat > "$pack/extension.vsixmanifest" <<XML
<?xml version="1.0" encoding="utf-8"?>
<PackageManifest Version="2.0.0"
  xmlns="http://schemas.microsoft.com/developer/vsx-schema/2011">
  <Metadata>
    <Identity Language="en-US" Id="zoom-step" Version="$version"
      Publisher="dotfiles"/>
    <DisplayName>Zoom Step</DisplayName>
    <Description>Zooms the window by 10% a step.</Description>
    <Properties>
      <Property Id="Microsoft.VisualStudio.Code.Engine"
        Value="^1.74.0"/>
    </Properties>
  </Metadata>
  <Installation>
    <InstallationTarget Id="Microsoft.VisualStudio.Code"/>
  </Installation>
  <Dependencies/>
  <Assets>
    <Asset Type="Microsoft.VisualStudio.Code.Manifest"
      Path="extension/package.json" Addressable="true"/>
  </Assets>
</PackageManifest>
XML
  (cd "$pack" && zip -q -X -r zoom-step.vsix '[Content_Types].xml' \
    extension.vsixmanifest extension)
  "$code" --install-extension "$pack/zoom-step.vsix" --force >/dev/null
  echo "  Installed zoom-step $version; it loads in each window on reload."
fi

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
