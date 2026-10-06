# Azure DevOps Boards

CLI: `az boards` (extension `azure-devops`).

| Operation | How |
|---|---|
| **view** | `az boards work-item show --id <n> --expand relations` (comments via REST `…/workItems/<n>/comments`) |
| **create** | `az boards work-item create --type Task --title … --description …` |
| **comment** | `az boards work-item update --id <n> --discussion "<text>"` |
| **claim** | `az boards work-item update --id <n> --assigned-to <me> --state Active` |
| **link** | `az boards work-item relation add --id <A> --relation-type Predecessor --target-id <B>` (B must finish first) |
| **blockers** | Relations of type `System.LinkTypes.Dependency-Reverse` whose target is not Closed/Done |
| **watch** | Poll **blockers** |
| **PR state** | `az repos pr show --id <n>` |
