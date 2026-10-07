#!/usr/bin/env bash
# One line per agent terminal: claude process, busy/idle, last status marker, last action line.
# Usage: agent-health.sh <terminal-id> [<terminal-id> ...]
# Output: <term> | <worktree> | claude=<pid>|none | busy|idle|exited | cpu=<ticks in 2s> shells=<n> | <marker> | <last action>
# An agent that says "waiting" while its screen shows "done <time>" or "N shells still running"
# and no work processes exist is usually stuck on a background job that never ends.
set -uo pipefail

OKENA="${OKENA:-okena}"

state=$("$OKENA" state)

term_path() {
  python3 -I -c '
import json, sys
term = sys.argv[1]
def has(node):
    if isinstance(node, dict):
        if node.get("terminal_id") == term:
            return True
        return any(has(v) for v in node.values())
    if isinstance(node, list):
        return any(has(v) for v in node)
    return False
for p in json.load(sys.stdin)["projects"]:
    if has(p.get("layout")):
        print(p["path"])
        break
' "$1" <<<"$state"
}

claude_pid() {
  local path="$1" pid cwd
  for pid in $(pgrep -x claude); do
    cwd=$(readlink "/proc/$pid/cwd" 2>/dev/null) || continue
    [ "$cwd" = "$path" ] && { echo "$pid"; return; }
  done
}

cpu_ticks() { awk '{print $14+$15}' "/proc/$1/stat" 2>/dev/null || echo 0; }

for t in "$@"; do
  path=$(term_path "$t")
  [ -n "$path" ] || { echo "$t | ? | terminal not found in okena state"; continue; }

  screen=$("$OKENA" read "$t" 2>/dev/null | grep -v '^\s*$' | grep -vE '^─|^❯|auto mode|shift\+tab')
  last=$(echo "$screen" | grep -E '^● ' | tail -1 | cut -c1-140)
  marker=$(echo "$screen" | grep -oE '(done [0-9:]+ ?[AP]M|[0-9]+ (shells?|monitors?) still running|Waiting for [0-9]+ background agent)' | tail -1)

  pid=$(claude_pid "$path")
  if [ -z "$pid" ]; then
    echo "$t | $path | claude=none | exited | - | ${marker:--} | ${last:--}"
    continue
  fi

  before=$(cpu_ticks "$pid"); sleep 2; after=$(cpu_ticks "$pid")
  shells=$(pgrep -P "$pid" | wc -l)
  if echo "$screen" | grep -qE 'esc to interrupt|…\s*\(|… [0-9]+s'; then status=busy; else status=idle; fi
  echo "$t | $path | claude=$pid | $status | cpu=$((after - before)) shells=$shells | ${marker:--} | ${last:--}"
done
