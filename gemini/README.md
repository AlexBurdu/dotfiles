# Gemini CLI

Config: [settings.json](./settings.json) | Instructions: [GEMINI.md](./GEMINI.md)

## Setup

```bash
gemini/setup.sh
```

Generates `~/.gemini/settings.json` by merging base settings with selected hook groups, then symlinks instructions and prompts for command groups.

## Structure

```
gemini/
  settings.json          # Base settings (editor, theme, tools, privacy, etc.)
  GEMINI.md              # Global instructions (commit format, conventions)
  hooks/
    tmux.json            # Tmux workdir tracking for tmux-pilot
    formatters.json      # Buildifier (.bzl) + ktfmt (.kt) auto-formatting
  commands/
    ...                  # Slash command groups (prompted during setup)
```

## Modular Hooks

Hooks are split into separate files under `hooks/`. Each file is a JSON fragment:

```json
{
  "_description": "Shown during setup prompt",
  "hooks": {
    "EventName": [...]
  }
}
```

During setup, each hook group is prompted independently. Selected hooks are merged into the base settings using array concatenation per event (so multiple groups can contribute to the same event like `AfterTool`). The final result is written to `~/.gemini/settings.json` via `merge_json`, which shows a diff and lets you accept, decline, or edit before writing.

### Hook groups

| File | Description | Requirements |
|---|---|---|
| `tmux.json` | `@pilot-workdir` tracking on file writes (tells tmux-pilot the agent's actual working directory) | tmux, [tmux-pilot](https://github.com/AlexBurdu/tmux-pilot) |
| `formatters.json` | Auto-format `.bzl` and `.kt` files after Gemini writes them | `buildifier`, `ktfmt` |
| `security-linters.json` | Security linters on file writes/edits (Kotlin, Python, Bash, JS/TS) | `detekt`, `bandit`, `shellcheck`, `semgrep` |

### Adding a new hook group

Create a JSON file in `hooks/` following the fragment format above. It will be picked up automatically on the next `setup.sh` run.

## merge_json

The setup uses the shared `bash/json_merge.sh` helper for the final write. It:

1. Shows a diff of what will change
2. Prompts with `y/n/e` — accept, decline, or open in `$EDITOR`
3. Validates JSON before writing (when editing)

This means `~/.gemini/settings.json` is a **generated file**, not a symlink. Any local edits to it will show up as a diff on the next setup run.
