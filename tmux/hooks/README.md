# Tmux Agent Hooks

Scripts that update tmux window names based on AI agent
state. Designed to complement
[tmux-pilot](https://github.com/AlexBurdu/tmux-pilot),
which manages **session** names (e.g., `claude-fix-42`).
These hooks manage **window** names to show what the agent
is currently doing.

## tmux-status-hook.sh

Updates the tmux window name to reflect agent activity.

### States

| State | Trigger | Window name | Purpose |
|-------|---------|-------------|---------|
| `activity` | PreToolUse | `reading`, `editing`, etc. | Show current tool activity |
| `working` | SessionStart, UserPromptSubmit | `working` | Agent is processing |
| `waiting` | Stop, AfterAgent | `✋22:55` | Waiting for user since HH:MM |
| `ready` | SessionEnd | `ready` | Agent is done |

### Activity Labels

When `activity` is triggered, the tool name from stdin
JSON is mapped to a human-readable label:

| Tool | Label |
|------|-------|
| Read, Glob, Grep | `reading` |
| Write, Edit, NotebookEdit | `editing` |
| Bash | `running` |
| Task | `delegating` |
| WebFetch, WebSearch | `searching` |
| (anything else) | `working` |

### Integration

**Claude Code** (`claude-code/settings.json`):
- `PreToolUse` → `activity` (reads tool name from stdin)
- `UserPromptSubmit` → `working`
- `Stop` → `waiting`
- `SessionStart` → `working`
- `SessionEnd` → `ready`

**Gemini CLI** (`gemini/settings.json`):
- `BeforeAgent` → `working`
- `AfterAgent` → `waiting`
- `SessionStart` → `working`
- `SessionEnd` → `ready`

Gemini doesn't expose per-tool hooks, so it only shows
`working`/`waiting` rather than specific activities.

### How It Complements tmux-pilot

tmux-pilot sets **session names** with task context:
```
claude-fix-42    gemini-review-17
```

This hook sets **window names** with agent state:
```
editing    ✋22:55    ready
```

Together, the tmux status bar shows both at a glance:
```
claude-fix-42:editing  gemini-review-17:✋22:55
```

No information is duplicated between session and window
names.

### Setup

The hook is symlinked by `tmux/setup.sh`:
```
~/.config/tmux/hooks/tmux-status-hook.sh
```

Both Claude Code and Gemini settings reference this path.

### Dependencies

- `tmux` (required)
- `date` (required, for waiting timestamp)
- `grep`, `sed` (for tool name extraction from JSON)
