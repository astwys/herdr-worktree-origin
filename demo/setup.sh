#!/usr/bin/env bash
# Start an isolated Herdr session and a throwaway Git repo for the demo recording.
set -euo pipefail
cd "$(dirname "$0")/.."

session=hwo-gif
root=/tmp/hwo-demo
repo="$root/demo-app"
herdr_config="$PWD/demo/herdr-config.toml"
h() { HERDR_CONFIG_PATH="$herdr_config" herdr --session "$session" "$@"; }

./demo/teardown.sh >/dev/null 2>&1 || true

# A bare "origin" with one branch that exists only on the remote.
mkdir -p "$root"
git init -q -b main "$root/origin.git" --bare
git init -q -b main "$repo"
git -C "$repo" remote add origin "$root/origin.git"
git -C "$repo" commit -q --allow-empty -m "initial commit"
git -C "$repo" push -q origin main
git -C "$repo" switch -q -c feature/billing
git -C "$repo" commit -q --allow-empty -m "billing"
git -C "$repo" push -q origin feature/billing
git -C "$repo" switch -q main
git -C "$repo" branch -q -D feature/billing
git -C "$repo" fetch -q --prune
git -C "$repo" branch -q feature/search
git -C "$repo" branch -q fix/login

HERDR_CONFIG_PATH="$herdr_config" nohup herdr --session "$session" server >/tmp/hwo-gif-server.log 2>&1 &
for _ in $(seq 1 50); do
  if h status server 2>&1 | grep -q 'status: running'; then
    break
  fi
  sleep 0.1
done

main=$(h workspace create --cwd "$repo" --label 'demo-app' --focus)
main_ws=$(jq -r '.result.workspace.workspace_id' <<<"$main")
# feature/search already has a worktree, so the picker opens it instead of creating one.
h worktree create --workspace "$main_ws" --branch feature/search --no-focus --trust-repository >/dev/null

echo "live demo session ready: herdr session attach $session"
