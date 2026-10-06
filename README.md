# my-skills

Personal [Claude Code](https://claude.com/claude-code) skills.

## Skills

| Skill | What it does |
|---|---|
| [orchestrate](skills/orchestrate/SKILL.md) | Turns a session into an orchestrator: every task becomes an issue and runs as a Claude agent in its own worktree and terminal session. Tracks agents, verifies their claims, watches blocked issues. |

## Install

Copy or symlink a skill folder into `~/.claude/skills/`:

```bash
git clone https://github.com/tomasfejfar/my-skills.git
ln -s "$PWD/my-skills/skills/orchestrate" ~/.claude/skills/orchestrate
```

The skill expects to live at `~/.claude/skills/orchestrate` (it calls its scripts by that path).

### orchestrate: adding a backend or tracker

`SKILL.md` defines the operations (**start**, **read**, **view**, **link**, ...). Each service maps them
in its own file:

- terminal backends: `skills/orchestrate/references/backends/<name>.md` (okena, tmux, zellij, wezterm, kitty, manual)
- issue trackers: `skills/orchestrate/references/trackers/<name>.md` (github, linear, jira, gitlab, azure-devops, markdown-file)

To add one, copy a similar file and fill a row for every operation. Helper scripts go in
`skills/orchestrate/scripts/<name>/`.
