#!/usr/bin/env bash
set -euo pipefail

herdr="${HERDR_BIN_PATH:-herdr}"
context="${HERDR_PLUGIN_CONTEXT_JSON-}"
if [[ -z "$context" ]]; then
  context='{}'
fi

fail() {
  printf '\n%s\n\nPress any key to close.\n' "$1"
  read -r -n 1 || true
  exit 0
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "Required command not found: $1"
}

require_command jq
require_command fzf
require_command git

workspace="${HERDR_WORKSPACE_ID:-$(jq -r '.workspace_id // empty' <<<"$context")}" \
  || fail "Herdr workspace context is required."
[[ -n "$workspace" ]] || fail "Herdr workspace context is required."

workspace_json=$("$herdr" workspace get "$workspace" 2>&1) || fail "$workspace_json"
repo=$(jq -r '.result.workspace.worktree.repo_root // empty' <<<"$workspace_json") \
  || fail "Herdr returned invalid workspace data."
if [[ -z "$repo" ]]; then
  workspace_cwd=$(jq -r '.workspace_cwd // empty' <<<"$context") \
    || fail "Herdr returned invalid plugin context."
  if [[ -n "$workspace_cwd" ]]; then
    repo=$(git -C "$workspace_cwd" rev-parse --show-toplevel 2>/dev/null || true)
  fi
fi
[[ -n "$repo" && -d "$repo" ]] || fail "The selected workspace is not inside a Git repository."

# Herdr exposes locally fetched remote-tracking refs. It does not fetch or
# query the network implicitly; run git fetch before opening this picker when
# you need newly-created remote branches to appear.
branch_output=$(git -C "$repo" for-each-ref \
  --format='%(refname)%09%(refname:short)' \
  refs/heads refs/remotes 2>&1) || fail "$branch_output"
branches=""
while IFS=$'\t' read -r full_ref short_ref; do
  [[ -z "$full_ref" || "$full_ref" == refs/remotes/*/HEAD ]] && continue
  branches+="${full_ref}"$'\t'"${short_ref}"$'\n'
done <<< "$branch_output"
branches=${branches%$'\n'}
[[ -n "$branches" ]] || fail "No local or fetched remote branches found."

choice=$(printf '%s\n' "$branches" | \
  fzf --delimiter=$'\t' --with-shell=bash \
      --header='Select a local or remote branch (esc to cancel)' \
      --with-nth=2 --layout=reverse --height=100%) || exit 0

ref=$(cut -f1 <<<"$choice")
short=$(cut -f2 <<<"$choice")
[[ -n "$ref" && -n "$short" ]] || fail "Could not read the selected branch."
local_branch="$short"
if [[ "$ref" == refs/remotes/* ]]; then
  local_branch="${short#*/}"
fi

worktree_json=$("$herdr" worktree list --workspace "$workspace" 2>&1) || fail "$worktree_json"
# Herdr refuses to open or create worktrees from a linked worktree workspace,
# so open and create go through the repo root instead of the current workspace.
existing=$(jq -r --arg branch "$local_branch" \
  '.result.worktrees[]? | select(.branch == $branch) | .path' \
  <<<"$worktree_json" | head -n1) || fail "Herdr returned invalid worktree data."
if [[ -n "$existing" ]]; then
  if ! response=$("$herdr" worktree open --cwd "$repo" --path "$existing" --focus 2>&1); then
    fail "$response"
  fi
  printf '%s\n' "$response"
  exit 0
fi

if [[ "$ref" == refs/heads/* ]]; then
  if ! response=$("$herdr" worktree create --cwd "$repo" --branch "$short" --focus 2>&1); then
    fail "$response"
  fi
  printf '%s\n' "$response"
  exit 0
fi

# A remote checkout uses a new local branch with the selected remote as its
# starting point. Refuse an existing local name instead of silently changing
# the selected remote's meaning.
remote_ref="$short"
if git -C "$repo" show-ref --verify --quiet "refs/heads/$local_branch"; then
  fail "Local branch '$local_branch' already exists. Select that local branch instead."
fi

response=$("$herdr" worktree create \
  --cwd "$repo" \
  --branch "$local_branch" \
  --base "$remote_ref" \
  --focus 2>&1) || fail "$response"
path=$(jq -r '.result.worktree.path // empty' <<<"$response") \
  || fail "Herdr returned invalid worktree data."
created_workspace=$(jq -r '.result.workspace.workspace_id // empty' <<<"$response") \
  || fail "Herdr returned invalid workspace data."
[[ -n "$path" && -n "$created_workspace" ]] || fail "$response"

if ! tracking_error=$(git -C "$path" branch --set-upstream-to="$remote_ref" "$local_branch" 2>&1); then
  # Best-effort rollback prevents a failed tracking operation from leaving an
  # orphaned Herdr workspace and checkout behind.
  "$herdr" worktree remove --workspace "$created_workspace" --force >/dev/null 2>&1 || true
  git -C "$repo" branch -D "$local_branch" >/dev/null 2>&1 || true
  fail "Could not configure tracking for '$local_branch': $tracking_error"
fi

printf '%s\n' "$response"
