# Herdr Worktree Branch Picker

A Herdr plugin that opens a popup branch picker from a workspace. It lists local
branches and **locally fetched** remote-tracking branches. It does not fetch or
access the network automatically; run `git fetch --all --prune` first when you
need fresh remote branches.

## Requirements

- Herdr 0.8.0+
- Bash
- Git
- [`fzf`](https://github.com/junegunn/fzf)
- [`jq`](https://jqlang.github.io/jq/)

## Install

```bash
herdr plugin link /path/to/herdr-worktree-origin
```

Add the shortcut to `~/.config/herdr/config.toml`:

```toml
[[keys.command]]
key = "prefix+b"
type = "plugin_action"
command = "herdr-worktree-origin.new-worktree-origin"
description = "open branch worktree"
```

Reload with `herdr server reload-config`, then press `Ctrl+A`, release it, and
press `b` from a Git workspace.

Selecting a local branch opens its existing worktree or creates one. Selecting
a fetched remote branch creates a local tracking branch and rolls back the
checkout if tracking setup fails.
