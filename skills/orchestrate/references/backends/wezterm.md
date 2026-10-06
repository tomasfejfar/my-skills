# WezTerm

One tab per agent through `wezterm cli`.

| Operation | How |
|---|---|
| **start** | `dir=../wt/<name>; git worktree add "$dir" -b <name> origin/main`<br>`pane=$(wezterm cli spawn --cwd "$dir")` (prints the pane id; keep it per agent)<br>`wezterm cli set-tab-title --pane-id "$pane" <name>`<br>`wezterm cli send-text --pane-id "$pane" --no-paste "claude -n <name> $(printf %q "$(cat prompt.txt)")"$'\r'` |
| **read** | `wezterm cli get-text --pane-id "$pane" \| tail -60` |
| **list** | `wezterm cli list` |
| **health** | **read** + grep for the markers |
| **remove** | `wezterm cli kill-pane --pane-id "$pane"; git worktree remove "$dir"` |
