#!/usr/bin/env bash
# Start a second Claude session as a new tab in an existing Okena worktree (e.g. implementation next to analysis).
# Usage: add-session.sh <terminal-id-in-that-worktree> <session-name> <prompt-file>
# Prints the new terminal id.
set -euo pipefail

OKENA="${OKENA:-okena}"
term="$1"
name="$2"
prompt_file="$3"

[[ "$name" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "invalid session name (allowed: A-Z a-z 0-9 . _ -): $name" >&2; exit 1; }

[ -s "$prompt_file" ] || { echo "prompt file empty or missing: $prompt_file" >&2; exit 1; }

tab=$("$OKENA" term tab "$term")
[ -n "$tab" ] || { echo "okena did not return a terminal id for the new tab" >&2; exit 1; }

prompt=$(cat "$prompt_file")
"$OKENA" run "$tab" "claude -n $(printf %q "$name") $(printf %q "$prompt")"
echo "$tab"
