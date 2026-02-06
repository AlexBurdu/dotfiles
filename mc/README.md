# Midnight Commander Configuration

Cross-platform mc configuration with support for macOS and Linux.

## Setup

```bash
cd mc
./setup.sh
```

This will:
1. Backup existing `~/.config/mc` to `~/.config/mc.bak`
2. Symlink this directory to `~/.config/mc`
3. Update `mc.ext.ini` to use the cross-platform file handlers

## Files

| File | Description |
|------|-------------|
| `setup.sh` | Setup script |
| `handlers.ini` | Cross-platform command mappings |
| `open-file.sh` | Script that reads handlers.ini and runs the OS-specific command |
| `mc.ext.ini` | File extension associations |
| `mc.keymap` | Custom keybindings (vim-style hjkl) |
| `ini` | Main mc settings |

## Cross-Platform File Handlers

### handlers.ini

Define commands for each file type per OS:

```ini
[image]
macos = open
linux = xdg-open

[video]
macos = open
linux = mpv

[pdf]
macos = open
linux = zathura

[default]
macos = open
linux = xdg-open
```

### Adding a New Handler

1. Add a section to `handlers.ini`:
   ```ini
   [audio]
   macos = open
   linux = mpv
   ```

2. Run `setup.sh` to update `mc.ext.ini`

The setup script scans `handlers.ini` and patches matching sections in `mc.ext.ini`:
- `[Include/TYPE]` sections (e.g., `[Include/image]`)
- Direct `[TYPE]` sections (e.g., `[pdf]`)

### How open-file.sh Works

```
open-file.sh <type> <file>
```

1. Detects the current OS (macOS or Linux)
2. Looks up the command for `<type>` in `handlers.ini`
3. Falls back to `[default]` if type not found
4. Executes the command with the file

## Keybindings

Custom vim-style navigation in `mc.keymap`:

| Key | Action |
|-----|--------|
| h/j/k/l | Navigate (left/down/up/right) |
| Tab | Change panel (empty command line) |
| Ctrl-Tab | Change panel |
