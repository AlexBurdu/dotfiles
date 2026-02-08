# VS Code Configuration

## Files

- `settings.json` - User settings (symlinked to VS Code config dir)
- `keybindings.json` - Custom keybindings (symlinked to VS Code config dir)
- `setup.sh` - Creates symlinks to VS Code's config location

## Section Formatting

Both JSON files use a consistent hierarchy for readability:

```jsonc
// ===========================================================================
// SECTION (H1)
// ===========================================================================

// SUBSECTION (H2)
// ---------------------------------------------------------------------------

// Sub-subsection (H3)
```

## Settings Organization

The `settings.json` is organized into sections for easy copying between
personal and work setups:

### Common (copied to work)

Everything above `// LOCAL CONFIG` is shared between personal and work:

- **GENERAL** - diffEditor, files, window, workbench basics
- **THEMING AND APPEARANCE** - fonts, colors, visual preferences
- **VIM CONFIGURATION** - VSCodeVim plugin settings and keybindings

### Local Config (personal only)

Settings under `// LOCAL CONFIG` are specific to the home setup and not
copied to work:

- **COPILOT** - GitHub Copilot settings
- **BAZEL** - Bazel build system settings
- **DART** - Dart/Flutter language settings
- **JAVA** - Java/Spring Boot settings
- **DATABASE** - Database client settings
- MCP gallery, file exclusions, other machine-specific settings

## Keybindings Organization

The `keybindings.json` follows the same pattern:

### Common

- **AI** - General inline suggestions, Gemini
- **NAVIGATION** - Editor, Terminal, Side Bar, List Navigation, Misc

### Local Config

- **COPILOT** - GitHub Copilot chat keybindings

## Setup

```bash
cd vscode
./setup.sh
```

This creates symlinks from VS Code's config directory to the dotfiles.
Changes made in VS Code will be reflected in the dotfiles.
