# herdr-worktree-origin

A Herdr plugin that opens a branch picker in a popup. Pick a branch and Herdr
focuses its worktree. If the branch has no worktree yet, the plugin creates one.

## Demo

![demo](demo/demo.gif)

## What a selection does

- If the branch already has a worktree, Herdr focuses it.
- If a local branch has no worktree, Herdr creates one and focuses it.
- If you pick a remote branch such as `origin/feature/billing`, the plugin
  creates a local `feature/billing` that tracks it, then creates the worktree.
  If a local branch with that name already exists, the plugin stops and asks
  you to pick the local branch. If tracking setup fails, it removes the new
  worktree and branch.

The picker lists local branches and the remote branches you have already
fetched. It never fetches, so run `git fetch --all --prune` first to see new
remote branches.

The picker works from the repo's main workspace and from any of its worktree
workspaces.

## Requirements

- Herdr 0.8.0+
- Bash, Git, [`fzf`](https://github.com/junegunn/fzf), [`jq`](https://jqlang.github.io/jq/)

## Install

```bash
herdr plugin install astwys/herdr-worktree-origin
```

Or while developing:

```bash
herdr plugin link /path/to/herdr-worktree-origin
```

### Keybinding

Herdr doesn't bind keys for plugins. Add one to `~/.config/herdr/config.toml`:

```toml
[[keys.command]]
key = "prefix+alt+w"
type = "plugin_action"
command = "herdr-worktree-origin.new-worktree-origin"
description = "open branch worktree"
```

Then run `herdr server reload-config`.

## Demo recording

```bash
./demo/setup.sh
vhs demo/demo.tape
./demo/teardown.sh
```

`setup.sh` starts an isolated Herdr session and a throwaway repo in
`/tmp/hwo-demo`.
