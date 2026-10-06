# kitty

One tab per agent through `kitty @`. Needs `allow_remote_control yes` (and `listen_on` when called from
outside kitty).

| Operation | How |
|---|---|
| **start** | `dir=../wt/<name>; git worktree add "$dir" -b <name> origin/main`<br>`kitty @ launch --type=tab --tab-title <name> --cwd "$dir"`<br>`kitty @ send-text --match title:<name> "claude -n <name> $(printf %q "$(cat prompt.txt)")"$'\r'` |
| **read** | `kitty @ get-text --match title:<name> \| tail -60` |
| **list** | `kitty @ ls` |
| **health** | **read** + grep for the markers |
| **remove** | `kitty @ close-tab --match title:<name>; git worktree remove "$dir"` |
