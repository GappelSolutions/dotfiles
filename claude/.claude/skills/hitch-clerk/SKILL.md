---
name: hitch-clerk
description: Azure DevOps conventions and commands for the hitch workflow (hitch-duck, hitch-tower). Covers the shape of Features, User Stories, Tasks, blocking links and PRs, states, and when a Story is ready. Load it when a hitch skill reads or writes work items, or when a hitch ticket is fixed by hand.
user-invocable: false
---

# hitch-clerk

Org and project are the `az devops configure` defaults. Auth is `$AZURE_DEVOPS_EXT_PAT`. Process: Agile.

```bash
org=$(az devops configure -l | sed -n 's/^organization = //p')   # https://dev.azure.com/<org>
project=$(az devops configure -l | sed -n 's/^project = //p')
```

## Convention

- **Feature**: the unit that gets grilled. Its description keeps the original text and gets a `## Design` section appended.
- **User Story** = one PR. Its parent is the Feature. In Story mode, the Story carries the `## Design` section itself.
- **Task** = one minimal step of its Story. Its parent is the Story.
- **Blocking**: if Story B is blocked by A, B gets a `Predecessor` link to A.
- **PR**: links to its Story only (`az repos pr create --work-items <story-id>`), never to a Task or Feature.
- Area: copy it from the parent or siblings.
- Iteration: don't set it. Sprint planning is done by humans.
- Tags: one component tag, reused from the siblings. Never invent one.
- State: new items start as `New`. Never delete. Close obsolete items (`Removed`) only with the user's OK.
- Lifecycle, set by hitch-tower. Nothing moves on its own: completing a PR doesn't change any state. `Resolved` isn't used for Stories.

  | when | Feature | Story + its Tasks |
  |---|---|---|
  | tower starts the Story (worktree) | `Active` if `New` | `Active`, assigned to the user |
  | its PR completes | | `Closed` |
  | every Story `Closed` | `Resolved`, only on the user's OK | |
  | Story dropped | | back to `New`, unassigned, only on the user's OK |

  ```bash
  me=$(curl -s -u ":$AZURE_DEVOPS_EXT_PAT" "<org>/_apis/connectionData" | jq -r '.authenticatedUser.properties.Account["$value"]')
  az boards work-item update --id <id> --state Active --assigned-to "$me"
  az boards work-item update --id <id> --state Closed
  ```
  Don't reassign an item someone else already holds: ask.
- Colleagues read these items, so write plain work items: no agent scaffolding, no bloat.

## Shapes

The Design section (on the grilled item):

````
## Design (YYYY-MM-DD)
**Scope**: …
**Out**: …
**Decisions**
- D1 …: why
**Sketches**
```sql
…
```
````

A Story:
- Title: the outcome, verb first.
- Description:
  ```
  <one line: what works after this PR>

  **Decisions**: F<id>/D1, D4   (or: none)
  **Checks**
  - auto: `<command>`
  - dev: <what to observe in your dev namespace>
  ```
- `Acceptance Criteria` field: bullets of observable behavior.

A Task: title only. Add ≤2 description lines if the step isn't obvious.

**Ready** means (checked by `hitch-bouncer`): a goal line, acceptance criteria, resolvable decision refs, checks, and every Predecessor `Closed`.

## Read

```bash
az boards work-item show --id <id> --expand all -o json   # fields + relations
az boards query --wiql "SELECT [System.Id] FROM WorkItems WHERE [System.Parent] = <id>" -o json
```

Relations: `System.LinkTypes.Hierarchy-Forward` = child, `-Reverse` = parent, `System.LinkTypes.Dependency-Reverse` = predecessor, `ArtifactLink` named `Pull Request` = its PR (the ID is the last segment of `vstfs:///Git/PullRequestId/…%2F<pr-id>`).

## Write (only after the user's "go")

Order: Feature (if new) → Stories in dependency order → Predecessor links → Tasks.

Create or update through REST so the descriptions are Markdown (existing items are HTML):

```bash
# create: POST .../workitems/$<type>   update: PATCH .../workitems/<id> ("replace" ops)
curl -s -u ":$AZURE_DEVOPS_EXT_PAT" -H 'Content-Type: application/json-patch+json' \
  -X POST "$org/$project/_apis/wit/workitems/\$User%20Story?api-version=7.1" -d @patch.json
```

```json
[
  {"op": "add", "path": "/fields/System.Title", "value": "…"},
  {"op": "add", "path": "/fields/System.Description", "value": "…markdown…"},
  {"op": "add", "path": "/multilineFieldsFormat/System.Description", "value": "markdown"},
  {"op": "add", "path": "/fields/Microsoft.VSTS.Common.AcceptanceCriteria", "value": "…markdown…"},
  {"op": "add", "path": "/multilineFieldsFormat/Microsoft.VSTS.Common.AcceptanceCriteria", "value": "markdown"},
  {"op": "add", "path": "/fields/System.AreaPath", "value": "<area of the parent>"},
  {"op": "add", "path": "/fields/System.Tags", "value": "<sibling tag>"},
  {"op": "add", "path": "/relations/-", "value": {"rel": "System.LinkTypes.Hierarchy-Reverse", "url": "<org>/_apis/wit/workItems/<parent-id>"}}
]
```

After the first write, read the item back and check its `multilineFieldsFormat`. If Markdown was rejected, fall back to minimal HTML.

```bash
az boards work-item relation add --id <B> --relation-type predecessor --target-id <A>
```

## PR

Conventions come from the repo's last completed PRs, never from its PR template:

```bash
az repos pr list --status completed --top 5 --query '[].[title, completionOptions.mergeStrategy, completionOptions.deleteSourceBranch]' -o tsv
```

- Title: their pattern (e.g. `#<story-id>: <story title>`).
- Description: plain Markdown for a colleague, readable like the tickets. No template checklist, no agent scaffolding:
  ```
  <one line: what works after this PR>

  **Changes**
  - <what>: <why, if not obvious>
  **Checks**
  - auto: `<command>` ✅
  - dev: <what was observed>
  **Review focus**: <the risky spot or one-way door; omit if none>
  ```
- Annotations: one thread per meaningful hunk, one sentence (what changed + intent), `Autogenerated` on generated files. They stay open: the author never resolves threads.

```bash
az repos pr create --draft --repository <repo> --source-branch <branch> --target-branch <default> \
  --work-items <story-id> --title "<title>" --description "$(cat pr.md)"
~/.claude/skills/hitch-tower/hitch-pr annotate <pr> annotations.tsv   # <path>:<line><TAB><text>
az repos pr update --id <pr> --description "$(cat pr.md)"             # keep it true after every push
az repos pr update --id <pr> --draft false                            # publish
az repos pr update --id <pr> --status completed --squash <bool> --delete-source-branch <bool>   # as their PRs do
```

Threads, via REST (`$repo` = the repository ID from `az repos pr show`):

```bash
t="$org/$project/_apis/git/repositories/$repo/pullRequests/<pr>/threads"
curl -s -u ":$AZURE_DEVOPS_EXT_PAT" "$t?api-version=7.1"                           # read; humans: commentType "text"
curl -s -u ":$AZURE_DEVOPS_EXT_PAT" -H 'Content-Type: application/json' -X POST \
  "$t/<thread>/comments?api-version=7.1" -d '{"content": "…", "parentCommentId": 1}' # reply
curl -s -u ":$AZURE_DEVOPS_EXT_PAT" -H 'Content-Type: application/json' -X PATCH \
  "$t/<thread>/comments/1?api-version=7.1" -d '{"content": "…"}'                     # edit an annotation
curl -s -u ":$AZURE_DEVOPS_EXT_PAT" -X DELETE "$t/<thread>/comments/1?api-version=7.1"  # drop an annotation
```

Syncing annotations after a push: edit the ones whose text no longer holds, delete those whose code is gone, and annotate new hunks. Only the author's own annotation threads, never anyone else's. Replies to colleagues only with the user's OK.

Votes: 10 approved, 5 approved with suggestions, 0 none, -5 waiting for author, -10 rejected.
