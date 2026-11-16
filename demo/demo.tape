# Record a real Herdr session. Regenerate with:
#
#   cd <plugin root>
#   ./demo/setup.sh
#   vhs demo/demo.tape
#   ./demo/teardown.sh
#
# setup.sh creates an isolated session and a throwaway repo in /tmp/hwo-demo.
# feature/billing exists only on origin, feature/search already has a worktree,
# and fix/login is a local branch without one.

Output demo/demo.gif
Set FontSize 18
Set Width 2200
Set Height 1100
Set Padding 40

Hide
Type "env -u HERDR_ENV HERDR_CONFIG_PATH=$PWD/demo/herdr-config.toml herdr session attach hwo-gif"
Enter
Sleep 1800ms
Type "clear"
Enter
Sleep 300ms
Show
Sleep 500ms
Type "git branch -a"
Enter
Sleep 1500ms

# A remote-only branch: create a local tracking branch and its worktree.
Ctrl+A
Type "w"
Sleep 700ms
Type "billing"
Sleep 800ms
Enter
Sleep 1800ms
Type "git status -sb"
Enter
Sleep 1800ms

# A branch that already has a worktree: open it.
Ctrl+A
Type "w"
Sleep 700ms
Type "search"
Sleep 800ms
Enter
Sleep 1800ms

# A local branch without a worktree: create one.
Ctrl+A
Type "w"
Sleep 700ms
Type "login"
Sleep 800ms
Enter
Sleep 1800ms
Type "git status -sb"
Enter
Sleep 2000ms
