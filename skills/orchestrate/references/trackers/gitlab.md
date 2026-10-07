# GitLab

CLI: `glab`.

| Operation | How |
|---|---|
| **view** | `glab issue view <n> --comments` |
| **create** | `glab issue create --title … --description …` |
| **comment** | `glab issue note <n> -m …` |
| **claim** | `glab issue update <n> --assignee @me` |
| **link** | `glab api -X POST projects/:id/issues/<A>/links -f target_project_id=:id -f target_issue_iid=<B> -f link_type=is_blocked_by`; remove with `DELETE …/links/<link_id>` |
| **blockers** | `glab api projects/:id/issues/<n>/links` → `link_type == "is_blocked_by"` and `state == "opened"` |
| **watch** | Poll **blockers** for open issues with links |
| **done-watch** | Poll `glab issue view <n> -F json` / `glab mr view <n> -F json` for `state` (`closed`, `merged`) |
| **PR state** | `glab mr view <n> -F json` (`state`, `merge_commit_sha`) |

Blocking links need GitLab Premium; else use `relates_to` + a label.
