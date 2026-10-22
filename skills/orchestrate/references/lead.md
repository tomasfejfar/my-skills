# Lead rules

These rules apply to every **lead**: a session that starts other Claude sessions. The orchestrator is
a lead, and so is any session it starts that starts sessions of its own (e.g. an implementation
session that starts one session per slice of the plan). A lead that is not the orchestrator reads only
this file, not the rest of the skill.

**Scope:** these rules cover Claude *sessions* only (started in a terminal, a multiplexer such as
Okena, or a worktree with `claude`). They do not cover subagents started with the Agent tool, also not
with `isolation: "worktree"`. For subagents, the Claude Code harness guidance applies unchanged.

**Scripts** are in `~/.claude/skills/orchestrate/scripts/`; only backend-specific ones are in
`scripts/<backend>/`. Write the full path into your notes and state file, never just the script name.
The skill folder is a symlink, so plain `find ~/.claude` does not see inside it; use `find -L`.

## Who owns what

- The session that starts another session is its lead. The lead is responsible for that session and
  for the worktree it runs in.
- One worktree can host several sessions at once. For example, a planning session writes a plan and
  starts an implementation session next to it in the same worktree.
- Responsibility forms a tree: each session is the lead of the sessions it starts. A session the user
  started directly has the user as its lead.

## Lead duties

- Keep track of every session you started: its worktree, its state, and the sessions it started in
  turn (as far as you know).
- Keep the overview, do not relay. Messages from your sessions update your state file; most need no
  reply. Never pass on a question a session asks the user: tell the session to ask the user directly
  in its own terminal, naming itself by session name + issue id + title.
- Check regularly that finished sessions are no longer running and that their worktrees are removed.
- **Sub-sessions never remove their own worktree**, even when a repo skill tells them to after a merge.
  This rule wins over repo skills. Put it in every handoff prompt: "When you are done, report to
  `<lead-name>` and do not remove your worktree or branch." Only the lead knows whether other sessions
  still use the worktree, so the lead cleans up.
- Before you remove a worktree:
  1. End the sub-sessions that run in it, once they are finished. A finished planning session does
     not mean the worktree is free: the implementation session may still work there.
  2. Run `~/.claude/skills/orchestrate/scripts/worktree-survey.sh <main-checkout>`. Its `processes`
     column must be empty (no session, server, watcher or test run), and check its `scratch` and
     `other-ignored` columns: ask whether `.scratch/` holds anything worth keeping.
  3. Remove only after the yes of your own lead (the user, or the session that started you).
  4. Right after the removal, run `~/.claude/skills/orchestrate/scripts/reap-worktree.sh <path> --kill`.

## Persistent lead state

- Keep the tracking state in a file, never only in context: `.scratch/lead-state.md` in your own
  worktree (the orchestrator: in the main checkout). Check that `.scratch/` is ignored by git there.
- The file records:
  - your own session name, the one your sub-sessions use to reach you (SendMessage name);
  - for every session you started: its name, how to reach it (terminal id, backend session,
    SendMessage name), its worktree and branch, its task (issue id and title), its state
    (running / waiting / done / ended), its PR, and the sessions it started in turn.
- Update the file at every change: a session started, finished or ended, a worktree removed, a PR
  opened or merged.
- A new lead session in the same worktree, or the same lead after compaction or a restart, reads this
  file first. Before it acts, it checks the file against reality: which sessions still run
  (ListAgents, **health**), which worktrees still exist (`worktree-survey.sh`), and the PR states.
- If the file and reality disagree, trust reality, fix the file, and tell your lead what differed.

## Your session name

- At start, after a restart and after compaction, check with ListAgents that your current session
  name still matches the name recorded in the state file.
- If it changed, you cannot rename yourself: `/rename` is a user command. Give the user the exact
  command, `/rename <recorded-name>`, and wait. Send no work to sub-sessions until the rename is done,
  because their reports would go to the old name.
