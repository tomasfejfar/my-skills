# Markdown file (no tracker)

Use only when the user has no tracker. Propose GitHub Issues on the repo first.

One file `.scratch/issues.md` with `## <ID> <title>` sections (state, blocked-by line, body, log). Every
agent edits only its own section; you are the only one who adds sections and links.

| Operation | How |
|---|---|
| **view** | Read the issue's section |
| **create** | Add a section with the next free ID |
| **comment** | Append a line to the section's log |
| **claim** | Set the section's state to `in progress (<session name>)` |
| **link** | Edit the `blocked-by:` line |
| **blockers** | IDs on the `blocked-by:` line whose state is not `done` |
| **watch** | Not available. Re-check blockers whenever an agent reports done. |
| **done-watch** | Not available for issues. Run **done-watch** on the PRs in the code host. |
| **PR state** | From the code host (e.g. `trackers/github.md`) |
