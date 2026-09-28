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
  | its PR is published | | Tasks to the taskboard's review column (state stays `Active`) |
  | its PR completes and the after-merge check passes | | `Closed` |
  | every Story `Closed` | `Resolved`, only on the user's OK | |
  | Story dropped | | back to `New`, unassigned, only on the user's OK |

  ```bash
  me=$(curl -s -u ":$AZURE_DEVOPS_EXT_PAT" "<org>/_apis/connectionData" | jq -r '.authenticatedUser.properties.Account["$value"]')
  az boards work-item update --id <id> --state Active --assigned-to "$me"
  az boards work-item update --id <id> --state Closed
  ```
  Don't reassign an item someone else already holds: ask.
- Taskboard column: separate from the state, per team, and only for a Task in a sprint. Team: the project's default team if its area paths cover the Task's area, else the team whose area paths do. Column: the one whose name contains "review" (e.g. `Code Review`, `In Review`). Task without a sprint, or no such column: skip and say so.

  ```bash
  a=(-s -u ":$AZURE_DEVOPS_EXT_PAT")
  team=$(curl "${a[@]}" "$org/_apis/projects/$project?api-version=7.1" | jq -r .defaultTeam.id)
  curl "${a[@]}" "$org/$project/$team/_apis/work/teamsettings/teamfieldvalues?api-version=7.1"     # its area paths
  curl "${a[@]}" "$org/$project/$team/_apis/work/taskboardcolumns?api-version=7.1-preview.1"       # its columns
  curl "${a[@]}" "$org/$project/$team/_apis/work/teamsettings/iterations?api-version=7.1"          # ID of the Task's IterationPath
  curl "${a[@]}" -H 'Content-Type: application/json' -X PATCH -d '{"newColumn": "<column>"}' \
    "$org/$project/$team/_apis/work/taskboardworkitems/<iteration-id>/<task-id>?api-version=7.1-preview.1"
  ```
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
  As a <role>, I want <capability>, so that <benefit>.

  **Decisions**: F<id>/D1, D4   (or: none)
  **Checks**
  - auto: `<command>`
  - dev: <input to send> → <what to read back> · cleanup: <what the check leaves behind>
  ```
  The role is someone who uses or runs the system (an operator, a meter admin), never "developer". The dev check runs against any deployed environment as is: it sends input and reads results, and never deploys or configures anything.
- `Acceptance Criteria` field: bullets of observable behavior.

A Task: title only. Add ≤2 description lines if the step isn't obvious.

**Ready** means (checked by `hitch-bouncer`): an "As a … I want … so that …" line with a real role, acceptance criteria, resolvable decision refs, checks, and every Predecessor `Closed`.

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
- Annotations: one thread per meaningful hunk, one sentence (what changed + intent), `Autogenerated` on generated files. They stay open: the author never resolves their own annotations.

```bash
az repos pr create --draft --repository <repo> --source-branch <branch> --target-branch <default> \
  --work-items <story-id> --title "<title>" --description "$(cat pr.md)"
~/.claude/skills/hitch-tower/hitch-pr annotate <pr> annotations.tsv   # <path>:<line><TAB><text>
az repos pr update --id <pr> --description "$(cat pr.md)"             # keep it true after every push
az repos pr update --id <pr> --draft false                            # publish
az repos pr update --id <pr> --status completed --squash <bool> --delete-source-branch <bool>   # as their PRs do
```

Threads, via REST. The base is the PR's own repository URL: its repo may sit in another project.

```bash
t="$(az repos pr show --id <pr> --query repository.url -o tsv)/pullRequests/<pr>/threads"
curl -s -u ":$AZURE_DEVOPS_EXT_PAT" "$t?api-version=7.1"                           # read; humans: commentType "text"
curl -s -u ":$AZURE_DEVOPS_EXT_PAT" -H 'Content-Type: application/json' -X POST \
  "$t/<thread>/comments?api-version=7.1" -d '{"content": "…", "parentCommentId": 1}' # reply
curl -s -u ":$AZURE_DEVOPS_EXT_PAT" -H 'Content-Type: application/json' -X PATCH \
  "$t/<thread>/comments/1?api-version=7.1" -d '{"content": "…"}'                     # edit an annotation
curl -s -u ":$AZURE_DEVOPS_EXT_PAT" -X DELETE "$t/<thread>/comments/1?api-version=7.1"  # drop an annotation
curl -s -u ":$AZURE_DEVOPS_EXT_PAT" -H 'Content-Type: application/json' -X PATCH \
  "$t/<thread>?api-version=7.1" -d '{"status": "fixed"}'                           # or "wontFix"
```

Syncing annotations after a push: edit the ones whose text no longer holds, delete those whose code is gone, and annotate new hunks. Only the author's own annotation threads, never anyone else's. Replies to colleagues only with the user's OK.

A thread with a colleague's comment is resolved only when the code shows it:
- `fixed`: the fix is pushed, and the reply names the commit.
- `wontFix`: the reply explains why not.
- A reply that only answers or asks leaves it `active`. The colleague resolves it, or asks for a change.

Votes: 10 approved, 5 approved with suggestions, 0 none, -5 waiting for author, -10 rejected.
