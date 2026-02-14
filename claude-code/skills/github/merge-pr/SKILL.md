---
description: Merge the current branch's PR and clean up the worktree
disable-model-invocation: true
---

This command is for use inside a worktree created by a
`git worktree add` workflow. It merges the PR, returns to
the main repo, and removes the worktree.

## Steps

1. Detect the current branch name. Abort if on `main` or
   `master`.

2. Determine the worktree root and the main repo root:
   ```
   git worktree list
   ```
   Abort if not inside a secondary worktree.

3. Gather PR and issue info before merging:
   ```
   gh pr view --json number,title,url,reviews,
     statusCheckRollup,additions,deletions,changedFiles
   ```
   Abort if no PR exists for this branch.

4. If the branch name matches `issue-<N>`, also fetch:
   ```
   gh issue view <N> --json title,body,url
   ```

5. Merge the PR (squash by default):
   ```
   gh pr merge --squash --delete-branch
   ```

6. Change directory to the main repo root.

7. Pull latest main:
   ```
   git pull --ff-only
   ```

8. Remove the worktree:
   ```
   git worktree remove <worktree-path>
   git worktree prune
   ```

9. Delete the local branch if it still exists:
   ```
   git branch -d <branch>
   ```

10. If running inside tmux, rename the window:
    ```
    command tmux rename-window "ready"
    ```

11. Print the completion summary:
    ```
    ═══ Merge Complete ═════════════════════════════
    Issue:    #<N> — <issue title>
              <issue URL>
              <first 2-3 lines of issue body, trimmed>
    PR:       #<M> — <PR title>
              <PR URL>
    Diff:     <changedFiles> files (+<additions> -<deletions>)
    Method:   Squash
    Checks:   ✓ all passed | ✗ <N> failed (list names)
    Reviews:  <reviewer names and status, e.g. "alex ✓">
    Cleanup:  Worktree removed, branch deleted
    ════════════════════════════════════════════════
    ```
    Omit the Issue section if the branch doesn't match an
    issue pattern or the issue lookup fails.

## Important

- Confirm with the user before running `gh pr merge`.
- If merge fails (e.g. checks not passing), stop and
  report the error — do NOT force merge.
