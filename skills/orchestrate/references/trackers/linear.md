# Linear

CLI: `linear` (e.g. `linear-cli`), or the Linear MCP server (`save_issue`, `get_issue`, `save_comment`,
`list_issues`), or GraphQL at `https://api.linear.app/graphql` with `LINEAR_API_KEY`.

| Operation | How |
|---|---|
| **view** | MCP `get_issue` (with comments: `list_comments`), or GraphQL `issue(id:"ENG-123"){title description state{name} comments{nodes{body}}}` |
| **create** | MCP `save_issue` (team, title, description) |
| **comment** | MCP `save_comment` |
| **claim** | `save_issue` with `assignee: "me"` and state "In Progress" |
| **link** | GraphQL `issueRelationCreate(input:{issueId:B, relatedIssueId:A, type: blocks})` (B blocks A); delete with `issueRelationDelete` |
| **blockers** | GraphQL `issue(id){inverseRelations{nodes{type issue{identifier state{type}}}}}`; open = state type not `completed`/`canceled` |
| **watch** | Poll **blockers** for issues of the team that have any `blocks` inverse relation |
| **PR state** | From the code host (e.g. `trackers/github.md`) |
