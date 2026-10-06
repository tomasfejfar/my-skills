# GitHub Issues

Default tracker. CLI: `gh`.

| Operation | How |
|---|---|
| **view** | `gh issue view <n> --comments` |
| **create** | `gh issue create --title … --body-file …` |
| **comment** | `gh issue comment <n> --body …` |
| **claim** | `gh issue edit <n> --add-assignee @me` |
| **link** | GraphQL `addBlockedBy` / `removeBlockedBy` (`issueId`, `blockingIssueId` = node ids from `gh issue view --json id`) |
| **blockers** | GraphQL `issue(number:n){blockedBy(first:10){nodes{number state}}}` |
| **watch** | `~/.claude/skills/orchestrate/scripts/github/watch-unblocked.sh <owner> <repo>` |
| **PR state** | `gh pr view <n> --json state,mergedAt,mergeCommit` |
