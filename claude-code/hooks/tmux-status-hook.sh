#!/usr/bin/env bash
# Claude Code hook: updates the tmux window name to
# reflect agent state (working / waiting / ready).
#
# Called by Claude Code hooks with JSON on stdin.
# Usage: tmux-status-hook.sh <state>
#   States: prompt, working, waiting, ready, resume
#
# Dependencies: git, gh (GitHub CLI), tmux

# Exit silently if not inside tmux.
[ -z "$TMUX" ] && exit 0

STATE="${1:-working}"
PANE_ID=$(tmux display-message -p '#{pane_id}')
STATE_FILE="/tmp/claude-tmux-${PANE_ID//[%]/_}"

save_name() { printf '%s' "$1" > "$STATE_FILE"; }

load_name() {
  if [ -f "$STATE_FILE" ]; then
    cat "$STATE_FILE"
  else
    echo "claude"
  fi
}

# Get current window name (strip emoji prefix if present).
current_name() {
  tmux display-message -p '#{window_name}' | sed 's/^[✋⏳]*//'
}

# Check if name contains issue/PR reference (worth preserving).
has_ref() {
  printf '%s' "$1" | grep -qE '(issue|pr)-[0-9]+'
}

# Detect PR/issue references from raw hook JSON
# on stdin (no JSON parser needed).
detect_refs() {
  local input pr_num issue_num
  input=$(cat)

  # GitHub URL patterns (most reliable).
  pr_num=$(printf '%s' "$input" \
    | grep -oE '/pull/[0-9]+' | head -1 \
    | grep -oE '[0-9]+')
  issue_num=$(printf '%s' "$input" \
    | grep -oE '/issues/[0-9]+' | head -1 \
    | grep -oE '[0-9]+')

  # Keyword + #N fallbacks.
  if [ -z "$pr_num" ]; then
    pr_num=$(printf '%s' "$input" \
      | grep -oiE '(review|pr) #[0-9]+' \
      | head -1 | grep -oE '[0-9]+')
  fi
  if [ -z "$issue_num" ]; then
    issue_num=$(printf '%s' "$input" \
      | grep -oiE '(fix|issue|close) #[0-9]+' \
      | head -1 | grep -oE '[0-9]+')
  fi

  # If we have a PR but no issue, look up the
  # linked issue from the PR body (Closes #N).
  if [ -n "$pr_num" ] && [ -z "$issue_num" ]; then
    issue_num=$(gh pr view "$pr_num" \
      --json body --jq '.body' 2>/dev/null \
      | grep -oiE '(closes|fixes|resolves) #[0-9]+' \
      | head -1 | grep -oE '[0-9]+')
  fi

  # Build the name.
  if [ -n "$pr_num" ] && [ -n "$issue_num" ]; then
    echo "pr-${pr_num}-issue-${issue_num}"
  elif [ -n "$pr_num" ]; then
    echo "pr-${pr_num}"
  elif [ -n "$issue_num" ]; then
    echo "issue-${issue_num}"
  fi
}

# Fall back to git branch name (issue-N pattern).
detect_branch() {
  local branch issue
  branch=$(git branch --show-current 2>/dev/null)
  issue=$(printf '%s' "$branch" \
    | sed -n 's/^issue-\([0-9][0-9]*\)$/\1/p')
  if [ -n "$issue" ]; then
    echo "issue-${issue}"
  fi
}

case "$STATE" in
  prompt)
    # Fired on UserPromptSubmit — parse the prompt for references.
    # Only update name if NEW refs found; preserve existing issue/PR.
    saved=$(load_name)
    new_ref=$(detect_refs)

    if [ -n "$new_ref" ]; then
      # New ref found in prompt — use it.
      name="$new_ref"
    elif has_ref "$saved"; then
      # No new ref, but we have a saved issue/PR — keep it.
      name="$saved"
    else
      # No ref anywhere — keep whatever we have.
      name="${saved:-claude}"
    fi
    save_name "$name"
    tmux rename-window -t "$PANE_ID" "$name"
    ;;
  working)
    # Fired on SessionStart — preserve existing issue/PR name,
    # otherwise try git branch, fall back to "claude".
    saved=$(load_name)

    if has_ref "$saved"; then
      # Preserve saved issue/PR reference.
      name="$saved"
    else
      # No saved ref — try branch, then "claude".
      name=$(detect_branch)
      name="${name:-claude}"
    fi
    save_name "$name"
    tmux rename-window -t "$PANE_ID" "$name"
    ;;
  waiting)
    # Fired on Stop — prepend hand emoji.
    # Preserve the saved name (don't overwrite).
    name=$(load_name)
    [ -z "$name" ] && name="claude"
    tmux rename-window -t "$PANE_ID" "✋${name}"
    ;;
  resume)
    # Fired on PreToolUse — Claude is working, remove hand.
    # Preserve the saved name (don't overwrite).
    name=$(load_name)
    [ -z "$name" ] && name="claude"
    tmux rename-window -t "$PANE_ID" "$name"
    ;;
  ready)
    # Fired on SessionEnd — clean up.
    tmux rename-window -t "$PANE_ID" "ready"
    rm -f "$STATE_FILE"
    ;;
esac

exit 0
