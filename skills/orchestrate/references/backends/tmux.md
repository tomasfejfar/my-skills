# tmux

One session (or window) per agent.

| Operation | How |
|---|---|
| **start** | `dir=../wt/<name>; git worktree add "$dir" -b <name> origin/main`<br>`tmux new-session -d -s <name> -c "$dir"` (or `tmux new-window -n <name> -c "$dir"`)<br>`tmux send-keys -t <name> "claude -n <name> $(printf %q "$(cat prompt.txt)")" Enter` |
| **add session** | `tmux new-window -t <session> -n <name> -c "$dir"`, then `tmux send-keys -t <session>:<name> "claude -n <name> $(printf %q "$(cat prompt.txt)")" Enter` |
| **read** | `tmux capture-pane -p -t <name> -S -60` |
| **list** | `tmux ls` |
| **health** | **read** + grep for the markers |
| **remove** | `tmux kill-session -t <name>; git worktree remove "$dir"` |
