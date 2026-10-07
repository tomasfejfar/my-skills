# zellij

One tab per agent. Reading the screen is weaker than in tmux: it dumps the focused pane to a file.

| Operation | How |
|---|---|
| **start** | `dir=../wt/<name>; git worktree add "$dir" -b <name> origin/main`<br>`zellij action new-tab --name <name> --cwd "$dir"`<br>`zellij action write-chars "claude -n <name> $(printf %q "$(cat prompt.txt)")"; zellij action write 13` |
| **add session** | `zellij action new-tab --name <name> --cwd "$dir"`, then `write-chars` + `write 13` as in **start** |
| **read** | `zellij action go-to-tab-name <name>`, then `zellij action dump-screen /tmp/<name>.txt && tail -60 /tmp/<name>.txt` |
| **list** | `zellij action query-tab-names` |
| **health** | **read** + grep for the markers |
| **remove** | `zellij action go-to-tab-name <name>; zellij action close-tab; git worktree remove "$dir"` |

`zellij action` targets the focused session; run inside it or set `ZELLIJ_SESSION_NAME`.
