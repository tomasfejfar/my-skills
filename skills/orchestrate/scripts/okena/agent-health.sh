#!/usr/bin/env bash
# One line per running agent terminal: last visible activity + whether it looks idle.
# Usage: agent-health.sh <terminal-id> [<terminal-id> ...]
# An agent that says "waiting" while its screen shows "done <time>" or "N shells still running"
# and no work processes exist is usually stuck on a background job that never ends.
set -uo pipefail

OKENA="${OKENA:-okena}"

for t in "$@"; do
  screen=$("$OKENA" read "$t" 2>/dev/null | grep -v '^\s*$' | grep -vE '^─|^❯|auto mode|shift\+tab')
  last=$(echo "$screen" | grep -E '^● ' | tail -1 | cut -c1-140)
  status=$(echo "$screen" | grep -oE '(done [0-9:]+ ?[AP]M|[0-9]+ shells? still running|Waiting for [0-9]+ background agent)' | tail -1)
  busy=$(echo "$screen" | grep -qE '…\s*\(' && echo busy || echo idle)
  echo "$t | $busy | ${status:--} | ${last:--}"
done
