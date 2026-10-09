#!/usr/bin/env bash
# Start a Claude agent in a new Okena worktree.
# Usage: start-agent.sh <okena-project> <worktree-and-session-name> <prompt-file>
# Prints the terminal id. The worktree branches from current main of the project.
set -euo pipefail

OKENA="${OKENA:-okena}"
project="$1"
name="$2"
prompt_file="$3"

[[ "$name" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "invalid session name (allowed: A-Z a-z 0-9 . _ -): $name" >&2; exit 1; }

[ -s "$prompt_file" ] || { echo "prompt file empty or missing: $prompt_file" >&2; exit 1; }

"$OKENA" worktree add "$project" "$name" --new-branch >&2

term=""
for _ in $(seq 1 30); do
  term=$("$OKENA" term ls "$name" 2>/dev/null | head -1 | cut -f1)
  [ -n "$term" ] && break
  sleep 2
done
[ -n "$term" ] || { echo "no terminal appeared for worktree $name" >&2; exit 1; }

prompt=$(cat "$prompt_file")
"$OKENA" run "$term" "claude -n $(printf %q "$name") $(printf %q "$prompt")"
echo "$term"
