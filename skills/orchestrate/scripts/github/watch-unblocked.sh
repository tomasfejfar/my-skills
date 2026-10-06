#!/usr/bin/env bash
# Print one line per GitHub issue whose last open blocker closed (blocked -> unblocked).
# Usage: watch-unblocked.sh <owner> <repo>   (run under the Monitor tool; re-arm on expiry)
set -uo pipefail

owner="$1"
repo="$2"
Q="{repository(owner:\"$owner\",name:\"$repo\"){issues(states:OPEN,first:100,orderBy:{field:UPDATED_AT,direction:DESC}){nodes{number title issueDependenciesSummary{blockedBy totalBlockedBy}}}}}"

snap() {
  gh api graphql -f query="$Q" --jq '.data.repository.issues.nodes[]
    | select(.issueDependenciesSummary.totalBlockedBy>0)
    | "\(.number)\t\(.issueDependenciesSummary.blockedBy)\t\(.title)"' 2>/dev/null
}

prev=$(snap)
while true; do
  sleep 120
  cur=$(snap) || continue
  [ -z "$cur" ] && continue
  join -t$'\t' <(echo "$prev" | sort) <(echo "$cur" | sort) \
    | awk -F'\t' '$2>0 && $4==0 {print "UNBLOCKED #"$1" "$3; fflush()}'
  prev=$cur
done
