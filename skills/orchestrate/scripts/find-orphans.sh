#!/usr/bin/env bash
# Report-only: processes of this user whose working directory was deleted (e.g. a removed worktree).
# Usage: find-orphans.sh [<path-prefix> ...]   (no prefix = every deleted cwd)
# One line per deleted directory:
#   <dir> | claude=<pids>|none | procs=<n> | rss=<MB> | orphans=<pid:comm,...>|none | <pid:comm,...>
# "orphans" are processes whose parent is pid 1 or a systemd user manager: nothing will ever end them.
# It never kills anything. To clean one directory up: reap-worktree.sh <dir> --kill (after the user's yes).
set -uo pipefail

uid=$(id -u)
rows=$(for p in /proc/[0-9]*; do
  [ "$(stat -c %u "$p" 2>/dev/null)" = "$uid" ] || continue
  cwd=$(readlink "$p/cwd" 2>/dev/null) || continue
  [[ "$cwd" == *" (deleted)" ]] || continue
  pid=${p#/proc/}
  comm=$(cat "$p/comm" 2>/dev/null) || continue
  ppid=$(awk '/^PPid:/{print $2}' "$p/status" 2>/dev/null)
  rss=$(awk '/^VmRSS:/{print $2}' "$p/status" 2>/dev/null)
  parent=$(cat "/proc/$ppid/comm" 2>/dev/null)
  orphan=no
  { [ "$ppid" = 1 ] || [ "$parent" = systemd ]; } && orphan=yes
  printf '%s\t%s\t%s\t%s\t%s\n' "${cwd% (deleted)}" "$pid" "$comm" "${rss:-0}" "$orphan"
done)

if [ "$#" -gt 0 ]; then
  rows=$(awk -F'\t' 'BEGIN { for (i = 1; i < ARGC; i++) { pre[i] = ARGV[i]; delete ARGV[i] } }
    { for (i in pre) if ($1 == pre[i] || index($1, pre[i] "/") == 1) { print; next } }' "$@" <<<"$rows")
fi

[ -n "$rows" ] || { echo "no processes with a deleted working directory"; exit 0; }

sort -t$'\t' -k1,1 <<<"$rows" | awk -F'\t' '
  function flush() {
    if (dir == "") return
    printf "%s | claude=%s | procs=%d | rss=%dMB | orphans=%s | %s\n", dir, (cl == "" ? "none" : cl), n, rss / 1024, (orph == "" ? "none" : orph), all
  }
  $1 != dir { flush(); dir = $1; cl = ""; n = 0; rss = 0; orph = ""; all = "" }
  {
    n++; rss += $4; item = $2 ":" $3
    all = (all == "" ? item : all "," item)
    if ($3 == "claude") cl = (cl == "" ? $2 : cl "," $2)
    if ($5 == "yes") orph = (orph == "" ? item : orph "," item)
  }
  END { flush() }'
