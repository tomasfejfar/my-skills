#!/usr/bin/env bash
# Print one line when a watched GitHub issue or PR closes or merges.
# Usage: watch-closed.sh <owner> <repo> <number> [<number> ...]   (issue and PR numbers mixed)
# Output: MERGED #<n> <title> | CLOSED #<n> <title>
set -uo pipefail

owner="$1"
repo="$2"
shift 2

fields=""
for n in "$@"; do
  fields+="n$n: issueOrPullRequest(number:$n){... on Issue{number state title} ... on PullRequest{number state title}} "
done
Q="{repository(owner:\"$owner\",name:\"$repo\"){$fields}}"

snap() {
  gh api graphql -f query="$Q" --jq '.data.repository[] | "\(.number)\t\(.state)\t\(.title)"' 2>/dev/null
}

prev=$(snap)
while true; do
  sleep 120
  cur=$(snap) || continue
  [ -z "$cur" ] && continue
  join -t$'\t' <(echo "$prev" | sort) <(echo "$cur" | sort) \
    | awk -F'\t' '$2=="OPEN" && $4!="OPEN" {print $4" #"$1" "$5; fflush()}'
  prev=$cur
done
