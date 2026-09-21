# Midnight Commander Configuration

Cross-platform mc configuration with support for macOS and Linux.

## Setup

```bash
cd mc
./setup.sh
```

This will:
1. Replace a legacy `~/.config/mc` symlink with a real directory
2. Symlink the static config (`handlers.ini`, `open-file.sh`, `mc.keymap`) back to this repo
3. Seed `~/.config/mc/ini` from `ini.template` if it does not exist yet
4. Generate `~/.config/mc/mc.ext.ini` from the tracked template, substituting
   `@MC_CONFIG@` for the real config path

## Repo vs. runtime

`~/.config/mc` is a real directory, not a symlink to this one. mc rewrites its
own state on exit, and `tmux/set-themes.sh` seds the skin into `ini` on every
appearance change — pointing that at the working tree left the repo permanently
dirty and, worse, baked the absolute path of whichever machine last ran
`setup.sh` into the tracked `mc.ext.ini`.

| In `~/.config/mc` | Kind | Source |
|-------------------|------|--------|
| `handlers.ini`, `open-file.sh`, `mc.keymap` | symlink | this repo, edits apply immediately |
| `mc.ext.ini` | generated | `mc/mc.ext.ini` with `@MC_CONFIG@` substituted |
| `ini` | runtime | seeded once from `mc/ini.template`, then owned by mc |
| `panels.ini` | runtime | created by mc |

Re-run `setup.sh` after editing `handlers.ini` or `mc/mc.ext.ini`. To reset your
mc settings to the shipped defaults, delete `~/.config/mc/ini` and re-run it.

## Files

| File | Description |
|------|-------------|
| `setup.sh` | Setup script |
| `handlers.ini` | Cross-platform command mappings |
| `open-file.sh` | Script that reads handlers.ini and runs the OS-specific command |
| `mc.ext.ini` | File extension associations (template; `@MC_CONFIG@` is substituted at setup) |
| `mc.keymap` | Custom keybindings (vim-style hjkl) |
| `ini.template` | Seed for `~/.config/mc/ini` — mc's own settings are not tracked |

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

2. Run `setup.sh` to regenerate `~/.config/mc/mc.ext.ini`

The setup script scans `handlers.ini` and patches matching sections in the generated
`~/.config/mc/mc.ext.ini` (the tracked copy keeps the `@MC_CONFIG@` placeholder):
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
