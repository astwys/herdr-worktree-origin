#!/usr/bin/env bash
set -euo pipefail

herdr="${HERDR_BIN_PATH:-herdr}"
: "${HERDR_WORKSPACE_ID:?Herdr workspace context is required}"

exec "$herdr" plugin pane open \
  --plugin "${HERDR_PLUGIN_ID:-herdr-worktree-origin}" \
  --entrypoint branch-picker \
  --placement popup \
  --width 80% \
  --height 20 \
  --focus
