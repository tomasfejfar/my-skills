# Okena

Default backend. Load the `okena` skill first. `okena` below means the binary in `$OKENA` if set, else
`okena` on PATH. The scripts do the same. Check that it is the build the user runs (`okena --version`).

| Operation | How |
|---|---|
| **start** | `~/.claude/skills/orchestrate/scripts/okena/start-agent.sh <project> <name> <prompt-file>` (prints the terminal id) |
| **add session** | `~/.claude/skills/orchestrate/scripts/okena/add-session.sh <terminal-id-in-worktree> <name> <prompt-file>` (new tab, prints its terminal id) |
| **read** | `okena read <term>` (full terminal id) |
| **list** | `okena ls`, `okena term ls <project>` |
| **health** | `~/.claude/skills/orchestrate/scripts/okena/agent-health.sh <term...>` (full terminal ids) |
| **remove** | `okena worktree rm <worktree-project>` (ends its sessions) |

- Okena creates the worktree itself (`okena worktree add <project> <name> --new-branch`), branched from
  current main of the project. The worktree copies the parent project's layout (all its tabs);
  `start-agent.sh` waits for all of them, keeps the first and closes the rest. Okena has no option for a
  single-terminal worktree.
- **health** finds the Claude process by its working directory (`/proc/<pid>/cwd` = worktree path), so
  `claude=none` / `exited` means the session ended, even if the screen still shows old output. `busy`
  comes from the screen (spinner, `esc to interrupt`); also look at `cpu` and `shells`.
- Worktrees created by Claude Code itself (`.claude/worktrees/*`) are not Okena projects. `okena ls`
  does not show them; `scripts/worktree-survey.sh` does. Remove them with `git worktree remove` +
  `git branch -d`.
- To resume an exited session in a worktree: `okena run <term> "claude -c"`. A session that still has
  scheduled tasks shows an exit dialog first (stop tasks / background / stay): **read** the screen and
  ask the user which one.
