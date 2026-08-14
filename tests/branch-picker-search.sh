#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
picker="$repo_root/bin/branch-picker.sh"

if grep -Fq -- '--nth=2' "$picker"; then
  echo "branch picker must not combine --nth=2 with --with-nth=2" >&2
  exit 1
fi

branches=$'refs/heads/main\tmain\nrefs/heads/feature/search\tfeature/search'
expected=$'refs/heads/feature/search\tfeature/search'
actual=$(printf '%s\n' "$branches" | fzf --delimiter=$'\t' --with-nth=2 --filter=feature/search)

if [[ "$actual" != "$expected" ]]; then
  printf 'expected %q, got %q\n' "$expected" "$actual" >&2
  exit 1
fi
