# VS Code Configuration

## Files

- `settings.json` - User settings (symlinked to VS Code config dir)
- `keybindings.json` - Custom keybindings (symlinked to VS Code config dir)
- `setup.sh` - Creates symlinks to VS Code's config location

## Settings Organization

The `settings.json` is organized into sections for easy copying between
personal and work setups:

### Common (copied to work)

Everything above `// Local Config` is shared between personal and work:

- **General settings** - files, window, workbench basics
- **Theming and Appearance** - fonts, colors, visual preferences
- **Vim Configuration** - VSCodeVim plugin settings and keybindings
- **Languages and Frameworks** - language-specific settings (Dart, Bazel, etc.)

### Local Config (personal only)

Settings under `// Local Config` are specific to the home setup and not
copied to work:

- File exclusions for personal projects
- Personal MCP/AI tool configurations
- Other machine-specific settings

## Setup

```bash
cd vscode
./setup.sh
```

This creates symlinks from VS Code's config directory to the dotfiles.
Changes made in VS Code will be reflected in the dotfiles.
