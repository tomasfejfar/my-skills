#!/usr/bin/env bash
# List, and with --kill end, every process of this user that runs in a worktree (live or deleted),
# plus all their descendants (MCP servers, browser bridges, Chrome).
# Usage: reap-worktree.sh <worktree-path> [--kill]
# Without --kill it only prints: <pid> <comm> <cwd>.
# With --kill: SIGTERM the claude sessions first and wait (their MCP children exit with them), then
# SIGTERM what is left, wait, SIGKILL the rest. Exits 1 if anything survives.
# Run it after the backend's **remove** (and the user's yes): removing a worktree does not always end
# the sessions in it.
set -uo pipefail

wt="${1:?usage: reap-worktree.sh <worktree-path> [--kill]}"
mode="${2:-list}"
[ "$mode" = list ] || [ "$mode" = --kill ] || { echo "unknown option: $mode" >&2; exit 1; }
[[ "$wt" = /* ]] || { echo "worktree path must be absolute: $wt" >&2; exit 1; }
wt="${wt%/}"
# A live path must be a linked worktree (.git is a file); never reap a main checkout.
if [ -e "$wt" ] && [ ! -f "$wt/.git" ]; then
  echo "not a linked worktree (no .git file): $wt" >&2
  exit 1
fi

uid=$(id -u)
# This script and its callers (e.g. the orchestrator's own session) are never targets.
protected=" "
p=$$
while [ "$p" -gt 1 ]; do
  protected+="$p "
  p=$(awk '/^PPid:/{print $2}' "/proc/$p/status" 2>/dev/null) || break
done

# Prints "<pid>\t<comm>\t<cwd>" for each target: cwd inside $wt, or a descendant of such a process.
targets() {
  for p in /proc/[0-9]*; do
    [ "$(stat -c %u "$p" 2>/dev/null)" = "$uid" ] || continue
    printf '%s\t%s\t%s\t%s\n' "${p#/proc/}" \
      "$(awk '/^PPid:/{print $2}' "$p/status" 2>/dev/null)" \
      "$(cat "$p/comm" 2>/dev/null)" \
      "$(readlink "$p/cwd" 2>/dev/null)"
  done | awk -F'\t' -v wt="$wt" -v protected="$protected" '
    {
      pid[NR] = $1; ppid[$1] = $2; comm[$1] = $3; cwd = $4
      sub(/ \(deleted\)$/, "", cwd); dir[$1] = cwd
      if (cwd == wt || index(cwd, wt "/") == 1) hit[$1] = 1
    }
    END {
      for (i = 1; i <= NR; i++) {
        p = pid[i]
        for (q = p; q != "" && q > 1; q = ppid[q]) if (q in hit) break
        if (q == "" || q <= 1 || index(protected, " " p " ")) continue
        printf "%s\t%s\t%s\n", p, comm[p], dir[p]
      }
    }'
}

alive() { kill -0 "$1" 2>/dev/null; }

wait_gone() {  # <seconds> <pid...>
  local deadline=$((SECONDS + $1)); shift
  while [ "$SECONDS" -lt "$deadline" ]; do
    local left=0
    for p in "$@"; do alive "$p" && left=1; done
    [ "$left" = 0 ] && return 0
    sleep 1
  done
}

list=$(targets)
if [ "$mode" = list ]; then
  [ -n "$list" ] && tr '\t' ' ' <<<"$list" || echo "no processes in $wt"
  exit 0
fi

[ -n "$list" ] || { echo "no processes in $wt"; exit 0; }

claudes=$(awk -F'\t' '$2 == "claude" {print $1}' <<<"$list")
if [ -n "$claudes" ]; then
  echo "ending claude sessions: $(paste -sd' ' <<<"$claudes")"
  kill -TERM $claudes 2>/dev/null
  wait_gone 15 $claudes
fi

rest=$(targets | cut -f1)
if [ -n "$rest" ]; then
  echo "SIGTERM: $(paste -sd' ' <<<"$rest")"
  kill -TERM $rest 2>/dev/null
  wait_gone 5 $rest
  rest=$(for p in $rest; do alive "$p" && echo "$p"; done)
  if [ -n "$rest" ]; then
    echo "SIGKILL: $(paste -sd' ' <<<"$rest")"
    kill -KILL $rest 2>/dev/null
    sleep 1
  fi
fi

left=$(targets)
[ -z "$left" ] || { echo "still running:"; tr '\t' ' ' <<<"$left"; exit 1; }
echo "nothing left in $wt"
