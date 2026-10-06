# Jira

CLI: `acli jira` (Atlassian) or `jira` (jira-cli), or REST `https://<site>.atlassian.net/rest/api/3` with
an API token.

| Operation | How |
|---|---|
| **view** | `jira issue view KEY-1 --comments 20` / `GET /issue/KEY-1?fields=summary,status,assignee,comment,issuelinks` |
| **create** | `jira issue create -p PROJ -t Task -s "<title>" -b "<body>"` |
| **comment** | `jira issue comment add KEY-1 "<text>"` |
| **claim** | `jira issue assign KEY-1 $(jira me)` and `jira issue move KEY-1 "In Progress"` |
| **link** | `jira issue link KEY-A KEY-B Blocks` (B blocks A; check the link name in the site's link types); remove via `DELETE /issueLink/<id>` |
| **blockers** | `issuelinks` where type is "Blocks" and `inwardIssue` exists; open = `statusCategory != done` |
| **watch** | JQL `issue in linkedIssues(KEY, "is blocked by")` per watched issue, or poll `issuelinks` of `issueLinkType = Blocks` issues |
| **PR state** | From the code host (e.g. `trackers/github.md`) |

Jira descriptions use ADF in REST v3; jira-cli converts markdown. Say "markdown may render differently"
if you post through the raw API.
