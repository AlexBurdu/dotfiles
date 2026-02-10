#!/usr/bin/env zsh
# Portable git worktree + agent launcher functions.
# Works with any git repo — auto-detects repo root and remote.
#
# Usage:
#   wt-create <issue-number>   Create worktree + claim issue
#   wt-launch <issue-number> [agent]  Create + tmux window + agent
#   wt-list                    List worktrees for current repo
#   wt-cleanup <issue-number>  Remove worktree + prune

# Enable experimental Claude Code agent teams
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1

# Get the basename of the current git repository.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Writes repo name to stdout (e.g. "alexlibraria").
# Returns:
#   1 if not inside a git repository.
_wt_repo_name() {
  basename "$(git rev-parse --show-toplevel 2>/dev/null)" || return 1
}

# Get the absolute path to the current git repository root.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Writes absolute path to stdout.
# Returns:
#   1 if not inside a git repository.
_wt_repo_root() {
  git rev-parse --show-toplevel 2>/dev/null || return 1
}

# Get the GitHub owner/repo identifier for the current repo.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Writes "owner/repo" to stdout (e.g. "AlexBurdu/alexlibraria").
# Returns:
#   1 if gh CLI is unavailable or repo has no GitHub remote.
_wt_gh_repo() {
  gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null || return 1
}

# Build the worktree path for a given issue number.
# Convention: ~/<repo-name>-worktree/issue-<N>
# Globals:
#   HOME
# Arguments:
#   $1 - issue number
# Outputs:
#   Writes the worktree path to stdout.
# Returns:
#   1 if repo name cannot be determined.
_wt_path() {
  local repo_name issue_num
  repo_name=$(_wt_repo_name) || return 1
  issue_num="$1"
  echo "$HOME/${repo_name}-worktree/issue-${issue_num}"
}

# Create a git worktree for an issue and claim it on GitHub.
# Creates branch issue-<N> from main, assigns the issue to
# yourself, and posts a "Starting work" comment.
# Globals:
#   HOME
# Arguments:
#   $1 - GitHub issue number
# Outputs:
#   Progress messages to stdout.
# Returns:
#   1 if not in a git repo, worktree already exists,
#   or git worktree add fails.
wt-create() {
  if [[ -z "$1" ]]; then
    echo "Usage: wt-create <issue-number>"
    return 1
  fi

  local issue_num="$1"
  local repo_root wt_path gh_repo

  repo_root=$(_wt_repo_root) || {
    echo "Error: not inside a git repository"; return 1
  }
  wt_path=$(_wt_path "$issue_num") || return 1
  gh_repo=$(_wt_gh_repo)

  if [[ -d "$wt_path" ]]; then
    echo "Worktree already exists: $wt_path"
    return 1
  fi

  # Create worktree with dedicated branch
  git -C "$repo_root" worktree add \
    -b "issue-${issue_num}" "$wt_path" main || return 1

  # Claim issue on GitHub if gh is available and repo detected
  if [[ -n "$gh_repo" ]]; then
    gh issue edit "$issue_num" --add-assignee "@me" \
      --repo "$gh_repo" 2>/dev/null || true
    gh issue comment "$issue_num" \
      --body "Starting work on this" \
      --repo "$gh_repo" 2>/dev/null || true
  fi

  echo "Created worktree: $wt_path (branch: issue-${issue_num})"
}

# Create a worktree (if needed) and launch an AI agent in a
# new tmux window. Defaults to Claude Code if no agent is
# specified.
# Globals:
#   HOME, TMUX
# Arguments:
#   $1 - GitHub issue number
#   $2 - agent name: "claude" (default) or "gemini"
# Outputs:
#   Opens a new tmux window named issue-<N>, or prints
#   instructions if not inside tmux.
# Returns:
#   1 if issue number is missing, agent is unknown, or
#   worktree creation fails.
wt-launch() {
  if [[ -z "$1" ]]; then
    echo "Usage: wt-launch <issue-number> [claude|gemini]"
    return 1
  fi

  local issue_num="$1"
  local agent="${2:-claude}"
  local wt_path

  wt_path=$(_wt_path "$issue_num") || return 1

  # Create worktree if it doesn't exist
  if [[ ! -d "$wt_path" ]]; then
    wt-create "$issue_num" || return 1
  fi

  # Determine agent command
  local agent_cmd
  case "$agent" in
    claude)  agent_cmd="claude" ;;
    gemini)  agent_cmd="gemini" ;;
    *)       echo "Unknown agent: $agent"; return 1 ;;
  esac

  # Launch in new tmux window
  if [[ -n "$TMUX" ]]; then
    tmux new-window -n "issue-${issue_num}" \
      "cd '$wt_path' && $agent_cmd"
  else
    echo "Not in tmux. cd into $wt_path and run $agent_cmd"
  fi
}

# List all git worktrees for the current repository.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Writes git worktree list output to stdout.
# Returns:
#   1 if not inside a git repository.
wt-list() {
  local repo_root
  repo_root=$(_wt_repo_root) || {
    echo "Error: not inside a git repository"; return 1
  }
  git -C "$repo_root" worktree list
}

# Remove a worktree for a given issue and prune stale entries.
# Globals:
#   HOME
# Arguments:
#   $1 - GitHub issue number
# Outputs:
#   Confirmation message to stdout.
# Returns:
#   1 if not in a git repo, worktree doesn't exist, or
#   git worktree remove fails.
wt-cleanup() {
  if [[ -z "$1" ]]; then
    echo "Usage: wt-cleanup <issue-number>"
    return 1
  fi

  local issue_num="$1"
  local repo_root wt_path

  repo_root=$(_wt_repo_root) || {
    echo "Error: not inside a git repository"; return 1
  }
  wt_path=$(_wt_path "$issue_num") || return 1

  if [[ ! -d "$wt_path" ]]; then
    echo "Worktree not found: $wt_path"
    return 1
  fi

  git -C "$repo_root" worktree remove "$wt_path" || return 1
  git -C "$repo_root" worktree prune

  echo "Removed worktree: $wt_path"
}
