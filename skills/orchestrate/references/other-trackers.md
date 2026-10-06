# Other issue trackers

Read this only when the work does not live in GitHub Issues. Confirm the tracker with the user, map the
tracker operations from SKILL.md for it, and save the mapping as a memory.

## What a tracker must give

| Operation | Must do |
|---|---|
| **view** | Title, description, state, assignee, comments of one issue. |
| **create** | New issue with title + markdown body (context, goal, plan, done-when). |
| **comment** | Add a comment (start notes, evidence, stale-finding notes). |
| **claim** | Assign to the agent's user (or move to "In progress" if assignment is not used). |
| **link** | "A is blocked by B" as a real relation, and remove it. Parent/sub-issue if supported. |
| **blockers** | The open blockers of one issue. |
| **watch** | One line per issue whose last open blocker closed. Poll every ~2 min, compare with the previous snapshot. |

Code host operations (**PR state**, merge commit) stay with the code host: `gh` for GitHub, `glab` for
GitLab, `az repos` for Azure DevOps.

Rules for every tracker:
- Prefer the official CLI; else an MCP server the session already has; else the REST/GraphQL API with a
  token from the environment (never print or log it).
- Agents need the same operations. Put the exact commands in every handoff prompt (claim, comment,
  create), or the agent will improvise.
- Keep the issue key in worktree and session names (`ENG-123-slug`), and say the key + title to the user.
- No blocked-by relation in the tracker → say so to the user. Use the closest thing (a "blocks" link
  type, a label plus a line in the description) and make **watch** read that.

Write a small `watch-unblocked-<tracker>.sh` next to the GitHub one if you need **watch**: snapshot
`id<TAB>open-blocker-count<TAB>title` for issues with any blocker, and print
`UNBLOCKED <id> <title>` when the count goes from >0 to 0.

## Linear

CLI: `linear` (e.g. `linear-cli`), or the Linear MCP server (`save_issue`, `get_issue`, `save_comment`,
`list_issues`), or GraphQL at `https://api.linear.app/graphql` with `LINEAR_API_KEY`.

| Operation | How |
|---|---|
| view | MCP `get_issue` (with comments: `list_comments`), or GraphQL `issue(id:"ENG-123"){title description state{name} comments{nodes{body}}}` |
| create | MCP `save_issue` (team, title, description) |
| comment | MCP `save_comment` |
| claim | `save_issue` with `assignee: "me"` and state "In Progress" |
| link | GraphQL `issueRelationCreate(input:{issueId:B, relatedIssueId:A, type: blocks})` (B blocks A); delete with `issueRelationDelete` |
| blockers | GraphQL `issue(id){inverseRelations{nodes{type issue{identifier state{type}}}}}`; open = state type not `completed`/`canceled` |
| watch | poll the blockers query for issues of the team that have any `blocks` inverse relation |

## Jira

CLI: `acli jira` (Atlassian) or `jira` (jira-cli), or REST `https://<site>.atlassian.net/rest/api/3` with
an API token.

| Operation | How |
|---|---|
| view | `jira issue view KEY-1 --comments 20` / `GET /issue/KEY-1?fields=summary,status,assignee,comment,issuelinks` |
| create | `jira issue create -p PROJ -t Task -s "<title>" -b "<body>"` |
| comment | `jira issue comment add KEY-1 "<text>"` |
| claim | `jira issue assign KEY-1 $(jira me)` and `jira issue move KEY-1 "In Progress"` |
| link | `jira issue link KEY-A KEY-B Blocks` (B blocks A; check the link name in the site's link types); remove via `DELETE /issueLink/<id>` |
| blockers | `issuelinks` where type is "Blocks" and `inwardIssue` exists; open = `statusCategory != done` |
| watch | JQL `issue in linkedIssues(KEY, "is blocked by")` per watched issue, or poll `issuelinks` of `issueLinkType = Blocks` issues |

Jira descriptions use ADF in REST v3; jira-cli converts markdown. Say "markdown may render differently"
if you post through the raw API.

## GitLab

CLI: `glab`.

| Operation | How |
|---|---|
| view | `glab issue view <n> --comments` |
| create | `glab issue create --title … --description …` |
| comment | `glab issue note <n> -m …` |
| claim | `glab issue update <n> --assignee @me` |
| link | `glab api -X POST projects/:id/issues/<A>/links -f target_project_id=:id -f target_issue_iid=<B> -f link_type=is_blocked_by`; remove with `DELETE …/links/<link_id>` |
| blockers | `glab api projects/:id/issues/<n>/links` → `link_type == "is_blocked_by"` and `state == "opened"` (blocking links need GitLab Premium; else `relates_to` + label) |
| watch | poll `blockers` for open issues with links |
| PR state | `glab mr view <n> -F json` (`state`, `merge_commit_sha`) |

## Azure DevOps Boards

CLI: `az boards` (extension `azure-devops`).

| Operation | How |
|---|---|
| view | `az boards work-item show --id <n> --expand relations` (comments via REST `…/workItems/<n>/comments`) |
| create | `az boards work-item create --type Task --title … --description …` |
| comment | `az boards work-item update --id <n> --discussion "<text>"` |
| claim | `az boards work-item update --id <n> --assigned-to <me> --state Active` |
| link | `az boards work-item relation add --id <A> --relation-type Predecessor --target-id <B>` (B must finish first) |
| blockers | relations of type `System.LinkTypes.Dependency-Reverse` whose target is not Closed/Done |
| watch | poll `blockers` |
| PR state | `az repos pr show --id <n>` |

## Plain markdown file / no tracker

If the user has no tracker, propose GitHub Issues on the repo first. If they decline, use one file
`.scratch/issues.md` with `## <ID> <title>` sections (state, blocked-by line, body, log). Every agent
edits only its own section; you are the only one who adds sections and links. There is no **watch**:
re-check blockers whenever an agent reports done.
