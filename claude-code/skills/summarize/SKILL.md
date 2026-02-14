---
description: Print a structured summary of the work done in this session
disable-model-invocation: true
---

Review the full conversation and produce a summary using the
template below.

## Gathering context

Before printing the summary, silently check:

1. If work was done on a GitHub issue, fetch its details:
   ```
   gh issue view <N> --json number,title,url
   ```
2. If a PR was created or updated, fetch its details:
   ```
   gh pr view --json number,title,url,additions,deletions,changedFiles
   ```
3. Collect any other URLs referenced during the session
   (docs, CI runs, external resources).

## Template

```
═══ Work Summary ═══════════════════════════════
Request:    <what the user asked — 1-2 sentences>

Issue:      #<N> — <issue title>
            <github issue URL>
PR:         #<M> — <PR title>
            <github PR URL>
            <changedFiles> files (+<additions> -<deletions>)

Changes:
  - <brief summary of each logical change>

Links:
  - <URL — short description>
═════════════════════════════════════════════════
```

## Rules

- Omit the Issue section if no issue was involved.
- Omit the PR section if no PR was created or updated.
- Omit the Links section if no other URLs are relevant.
- Keep each Changes bullet to one line; wrap to a second
  indented line only if needed.
- If work is incomplete or blocked, add a Status line at
  the end explaining what remains.
