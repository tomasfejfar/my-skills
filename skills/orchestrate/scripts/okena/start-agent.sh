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

# The worktree copies the parent project's layout, so it gets as many terminals as the parent has.
# They appear after `worktree add` returns: wait for all of them, keep the first, close the rest.
expected=$("$OKENA" term ls "$project" | wc -l)
[ "$expected" -gt 0 ] || { echo "project $project has no terminals" >&2; exit 1; }

"$OKENA" worktree add "$project" "$name" --new-branch >&2

terms=""
for _ in $(seq 1 30); do
  terms=$("$OKENA" term ls "$name" 2>/dev/null | cut -f1)
  [ -n "$terms" ] && [ "$(wc -l <<<"$terms")" -ge "$expected" ] && break
  sleep 2
done
[ -n "$terms" ] && [ "$(wc -l <<<"$terms")" -ge "$expected" ] \
  || { echo "worktree $name has $(grep -c . <<<"$terms") of $expected terminals after 60 s" >&2; exit 1; }

term=$(head -1 <<<"$terms")
tail -n +2 <<<"$terms" | while read -r extra; do "$OKENA" term close "$extra"; done

prompt=$(cat "$prompt_file")
"$OKENA" run "$term" "claude -n $(printf %q "$name") $(printf %q "$prompt")"
echo "$term"
