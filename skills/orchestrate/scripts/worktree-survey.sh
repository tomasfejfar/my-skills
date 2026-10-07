#!/usr/bin/env bash
# One line per linked worktree of a repo, with everything needed before removing it.
# Usage: worktree-survey.sh <main-checkout-path>
# Columns: name | path | branch | last commit | merged into origin/<default> | uncommitted files |
#          files in .scratch/ (ignored, lost on remove) | other ignored entries (caches, deps, .env left out) |
#          pushed | processes with cwd inside
# Lists every worktree git knows, also ones the session backend does not track (e.g. .claude/worktrees/*).
set -uo pipefail

main="$1"
git -C "$main" fetch -q origin
default=$(git -C "$main" symbolic-ref --short refs/remotes/origin/HEAD | sed 's|^origin/||')
remote_heads=$(git -C "$main" ls-remote --heads origin)
proc_cwds=$(for p in /proc/[0-9]*; do
  cwd=$(readlink "$p/cwd" 2>/dev/null) && printf '%s\t%s:%s\n' "$cwd" "${p#/proc/}" "$(cat "$p/comm" 2>/dev/null)"
done)
noise='(^|/)(__pycache__|node_modules|vendor|\.venv|venv|target|dist|build|\.[a-z_]*cache|\.env)(/|$)'

printf 'name\tpath\tbranch\tlast-commit\tmerged\tuncommitted\tscratch\tother-ignored\tpushed\tprocesses\n'
git -C "$main" worktree list --porcelain | awk '/^worktree /{print substr($0, 10)}' | tail -n +2 | while read -r wt; do
  name=$(basename "$wt")
  if [ ! -d "$wt" ]; then
    printf '%s\t%s\t-\t-\t-\t-\t-\t-\t-\tMISSING (git worktree prune)\n' "$name" "$wt"
    continue
  fi
  branch=$(git -C "$wt" branch --show-current)
  last=$(git -C "$wt" log -1 --format=%cr)
  if git -C "$wt" merge-base --is-ancestor HEAD "origin/$default"; then merged=yes; else merged=no; fi
  uncommitted=$(git -C "$wt" status --porcelain | wc -l)
  scratch=0
  [ -d "$wt/.scratch" ] && scratch=$(find "$wt/.scratch" -type f | wc -l)
  other=$(git -C "$wt" status --porcelain --ignored | sed -n 's/^!! //p' | grep -v '^\.scratch/' | grep -vE "$noise" | paste -sd, -)
  if [ -z "$branch" ]; then
    pushed="detached"
  else
    remote_sha=$(awk -F'\t' -v ref="refs/heads/$branch" '$2==ref {print $1}' <<<"$remote_heads")
    if [ -z "$remote_sha" ]; then pushed="no (local only)"
    elif [ "$remote_sha" = "$(git -C "$wt" rev-parse HEAD)" ]; then pushed=yes
    else pushed="differs from origin"; fi
  fi
  procs=$(awk -F'\t' -v wt="$wt" '$1==wt || index($1, wt"/")==1 {print $2}' <<<"$proc_cwds" | paste -sd, -)
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$name" "$wt" "${branch:--}" "$last" "$merged" "$uncommitted" "$scratch" "${other:--}" "$pushed" "${procs:--}"
done
