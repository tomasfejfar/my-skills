# Terminals the user opens

No multiplexer: you create the worktree and the user starts the session.

| Operation | How |
|---|---|
| **start** | `dir=../wt/<name>; git worktree add "$dir" -b <name> origin/main`, then print one line for the user: `cd <dir> && claude -n <name> "$(cat <prompt-file>)"` |
| **read** | Not available. Use the agent's SendMessage reports. |
| **list** | `ListAgents` + `git worktree list` |
| **health** | `ListAgents` (busy/idle) + process checks in the worktree (`ps -eo pid,etime,args \| grep <dir>`) |
| **remove** | Ask the user to close the session, then `git worktree remove "$dir"` |

Ask the user to glance at a session when an agent is quiet for long.
