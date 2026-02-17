# Tmux Agent Hooks

## tmux-status-hook.sh

Updates the tmux window name to reflect agent activity.
Maps states like `activity`, `working`, `waiting`, `ready`
to short window-name labels.

> **Note**: This hook is no longer called by Claude Code or
> Gemini CLI settings. The agent hooks were removed because
> they couldn't reliably detect permission prompts (which
> happen mid-turn with no hook event). Agent state tracking
> is now intended to be handled by an external watchdog that
> reads actual pane content via tmux-pilot's `monitor_agents`
> tool and sets `@pilot-status` / `@pilot-needs-help` pane
> variables.

The script remains available for manual use or custom
integrations:

```bash
tmux-status-hook.sh activity   # reads tool name from stdin JSON
tmux-status-hook.sh working    # agent is processing
tmux-status-hook.sh waiting    # waiting for user (shows ✋HH:MM)
tmux-status-hook.sh ready      # agent is done
```

### Setup

Symlinked by `tmux/setup.sh`:
```
~/.config/tmux/hooks/tmux-status-hook.sh
```

### Dependencies

- `tmux` (required)
- `date` (required, for waiting timestamp)
- `grep`, `sed` (for tool name extraction from JSON)
