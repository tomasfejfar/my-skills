# Other session backends

Read this only when the `okena` skill is not available. Ask the user which backend they want, then map
the five operations from SKILL.md for it and save the mapping as a memory.

## What a backend must give

| Operation | Must do |
|---|---|
| **start** | Create a git worktree from current main (`git worktree add <dir> -b <name> origin/<main>`), open a terminal session named `<name>` in it, run `claude -n <name> "<prompt>"` there. |
| **read** | Show the visible screen (or the last ~50 lines) of that session, so you can see activity and idleness. |
| **list** | List live agent sessions and their worktrees. |
| **health** | Per agent: busy/idle, the last action line, and `done <time>` / `N shells still running` markers. Usually **read** + grep. |
| **remove** | End the session, then `git worktree remove <dir>` (and `git branch -d <name>` if merged). |

Keep the user able to watch and type into each agent. That is the reason for a multiplexer instead of
subagents or headless runs.

Quote the prompt safely: write it to a file and pass `"$(cat <file>)"` or `$(printf %q "$prompt")`.
Never paste a multi-line prompt as raw keystrokes without quoting; newlines submit early.

## Question to ask the user

Offer the options in plain text:

1. **tmux** - one session or window per agent; you read panes with `capture-pane`.
2. **zellij** - one tab per agent; reading the screen is weaker (dump to file).
3. **WezTerm / kitty** - one tab per agent via their CLI; needs remote control enabled.
4. **Separate terminals the user opens** - you only create worktrees and print the exact command for the
   user to paste; read/health then rely on SendMessage reports and process checks.
5. Something else - the user describes it, you map the five operations.

## tmux

```bash
dir=../wt/<name>; git worktree add "$dir" -b <name> origin/main
tmux new-session -d -s <name> -c "$dir"                       # or: tmux new-window -n <name> -c "$dir"
tmux send-keys -t <name> "claude -n <name> $(printf %q "$(cat prompt.txt)")" Enter
tmux capture-pane -p -t <name> -S -60                         # read
tmux ls                                                       # list
tmux kill-session -t <name>; git worktree remove "$dir"       # remove
```

## zellij

```bash
dir=../wt/<name>; git worktree add "$dir" -b <name> origin/main
zellij action new-tab --name <name> --cwd "$dir"
zellij action write-chars "claude -n <name> $(printf %q "$(cat prompt.txt)")"; zellij action write 13
zellij action dump-screen /tmp/<name>.txt && tail -60 /tmp/<name>.txt   # read (focused pane only: go-to-tab-name first)
zellij action go-to-tab-name <name>
zellij action close-tab; git worktree remove "$dir"                     # remove (after go-to-tab-name)
```

`zellij action` targets the focused session; run inside it or set `ZELLIJ_SESSION_NAME`.

## WezTerm

```bash
dir=../wt/<name>; git worktree add "$dir" -b <name> origin/main
pane=$(wezterm cli spawn --cwd "$dir")                         # prints pane id; keep it per agent
wezterm cli set-tab-title --pane-id "$pane" <name>
wezterm cli send-text --pane-id "$pane" --no-paste "claude -n <name> $(printf %q "$(cat prompt.txt)")"$'\r'
wezterm cli get-text --pane-id "$pane" | tail -60              # read
wezterm cli list                                               # list
wezterm cli kill-pane --pane-id "$pane"; git worktree remove "$dir"
```

## kitty

Needs `allow_remote_control yes` (and `listen_on` when called from outside kitty).

```bash
dir=../wt/<name>; git worktree add "$dir" -b <name> origin/main
kitty @ launch --type=tab --tab-title <name> --cwd "$dir"
kitty @ send-text --match title:<name> "claude -n <name> $(printf %q "$(cat prompt.txt)")"$'\r'
kitty @ get-text --match title:<name> | tail -60               # read
kitty @ ls                                                     # list
kitty @ close-tab --match title:<name>; git worktree remove "$dir"
```

## User-opened terminals

You create the worktree and print one line for the user:

```text
cd <dir> && claude -n <name> "$(cat <prompt-file>)"
```

There is no **read**: watch agents through their SendMessage reports, `ListAgents` (busy/idle), and
process checks in the worktree. Ask the user to glance at a session when an agent is quiet for long.

## After choosing

Save a memory such as: "orchestrate backend: tmux; start = …, read = …, remove = …". Keep the
per-agent identifiers (tmux session, pane id, tab title) in the handoff notes so later **read** and
**remove** calls hit the right session.
