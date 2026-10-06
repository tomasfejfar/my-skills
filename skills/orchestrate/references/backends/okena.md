# Okena

Default backend. Load the `okena` skill first. Use the binary in `$OKENA` if set, else `okena` on PATH
(the scripts below do the same).

| Operation | How |
|---|---|
| **start** | `~/.claude/skills/orchestrate/scripts/okena/start-agent.sh <project> <name> <prompt-file>` (prints the terminal id) |
| **read** | `okena read <term>` |
| **list** | `okena ls`, `okena term ls <project>` |
| **health** | `~/.claude/skills/orchestrate/scripts/okena/agent-health.sh <term...>` |
| **remove** | `okena worktree rm <worktree-project>` (ends its session) |

Okena creates the worktree itself (`okena worktree add <project> <name> --new-branch`), branched from
current main of the project. Worktrees it does not track: `git worktree remove` + `git branch -d`.
