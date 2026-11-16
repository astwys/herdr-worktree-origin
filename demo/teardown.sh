#!/usr/bin/env bash
# Remove the isolated Herdr session and demo repo created by setup.sh.
set -euo pipefail

session=hwo-gif
herdr session stop "$session" >/dev/null 2>&1 || true
herdr session delete "$session" >/dev/null 2>&1 || true
rm -rf /tmp/hwo-demo
