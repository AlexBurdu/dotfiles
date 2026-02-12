# Tmux Session Description

When working inside tmux, update the pane description so the task is visible in the tmux-pilot deck. Run this early — once you understand the task — and again if the user changes direction:

```bash
[ -n "$TMUX" ] && command tmux set-option -p @pilot-desc "SHORT DESCRIPTION"
```

Keep it under 80 characters. Include the issue/PR link or number if available (e.g. `Fix login redirect loop #42`). Focus on *what* and *why*, not implementation details.

# Git Commits

- Format: Description starting with uppercase (e.g. `Add portable worktree functions`)
- Description max 256 characters
- Optional body/footer separated by blank lines
- If working on a tracked issue, reference it (e.g. `Handle null response #42`)
- Do NOT add `Co-Authored-By` lines to commits

# Pull Requests

- Use GitHub PR labels for categorization (e.g. `bug`, `enhancement`, `refactor`)
- Do NOT encode type in commit messages or PR titles
- Do NOT add "Generated with" watermark lines to pull requests
