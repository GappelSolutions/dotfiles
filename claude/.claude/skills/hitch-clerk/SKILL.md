---
name: hitch-clerk
description: Azure DevOps conventions and commands for the hitch workflow (hitch-duck, hitch-tower). Covers the shape of User Stories and their Tasks (one slice = one PR each), blocking links and PRs, states, and when a Task is ready. Load it when a hitch skill reads or writes work items, or when a hitch ticket is fixed by hand. /hitch-clerk publishes the user's own branch as a hitch PR.
argument-hint: "[task-id | story-id] [branch]"
---

# hitch-clerk

Invoked by the user as `/hitch-clerk` (input: `$ARGUMENTS`): read `~/.claude/skills/hitch-clerk/PUBLISH.md` and follow it, with this file as the reference. Loaded by another skill: reference only.

Org and project are the `az devops configure` defaults. Auth is `$AZURE_DEVOPS_EXT_PAT`. Process: Agile.

```bash
org=$(az devops configure -l | sed -n 's/^organization = //p')   # https://dev.azure.com/<org>
project=$(az devops configure -l | sed -n 's/^project = //p')
```

## Convention

- **Feature**: the PO's. Context only: hitch reads it and never writes to it, not even its state.
- **User Story**: the unit that gets grilled. Its description keeps the original text and gets a `## Design` section appended. Its parent is a Feature, if there is one. A new Story only if the PO could ship or drop it on its own (another role or benefit). It gets its own Design, with no refs to another Story's.
- **Task** = one slice = one PR. Its parent is the Story. It carries no decisions: the Design lives on the Story, once.
- **Blocking**: if Task B is blocked by A, B gets a `Predecessor` link to A.
- **PR**: links to its Task and its Story (`az repos pr create --work-items <task-id> <story-id>`), never to a Feature. Tower completes it with `--transition-work-items false`, so a merge never closes the Story.
- Area: copy it from the parent or siblings.
- Iteration: don't set it. Sprint planning is done by humans.
- Tags: one component tag, reused from the siblings. Never invent one.
- State: new items start as `New`. Never delete. Close obsolete items (`Removed`) only with the user's OK.
- Lifecycle, set by hitch-tower. Nothing moves on its own: completing a PR doesn't change any state. `Resolved` isn't used.

  | when | Story | Task |
  |---|---|---|
  | tower starts a Task (worktree) | `Active` if `New`, assigned to the user | `Active`, assigned to the user |
  | its PR is published | | to the taskboard's review column (state stays `Active`) |
  | its PR completes and the after-merge check passes | | `Closed` |
  | every Task `Closed` | `Closed` | |
  | Task dropped | | back to `New`, unassigned, only on the user's OK |

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
- Colleagues read these items, so write plain work items: no agent scaffolding, no bloat. Nothing they can't open: no refs to local ADRs or `~/.hitch/` files, in work items, PRs or annotations.

## Shapes

A Story:
- Title: the outcome, verb first.
- Description: the story line, then the Design. An existing Story keeps its text and gets the Design appended. If it has no story line, propose one at the gate.
  ````
  As a <role>, I want <capability>, so that <benefit>.

  ## Design (YYYY-MM-DD)
  **Scope**: …
  **Out**: …
  **Decisions**
  *System*
  - D1 …: why
  *Program*
  - D4 …: why
  **Sketches**
  ```sql
  …
  ```
  ````
  The role is someone who uses or runs the system (an operator, a meter admin), never "developer".
- `Acceptance Criteria` field: bullets of observable behavior. Tasks have no such field.

A Task:
- Title: the slice's outcome, verb first, ≤60 chars, no IDs. On the taskboard it's all anyone reads.
- Description:
  ```
  <1–2 lines: what works after this PR>
  - auto: `<command>`
  - dev: <input to send> → <what to read back> · cleanup: <what the check leaves behind>
  ```
  No steps: the mechanic plans its own commits. The dev check runs against any deployed environment as is: it sends input and reads results, and never deploys or configures anything. A prefactor without behavior change: `dev: none, no behavior change`.

**Ready** means (checked by `hitch-bouncer`, per Task):
- Story: an "As a … I want … so that …" line with a real role, acceptance criteria, a `## Design`.
- Task: the scope line, checks, every Predecessor `Closed`.

## Read

```bash
az boards work-item show --id <id> --expand all -o json   # fields + relations
az boards query --wiql "SELECT [System.Id] FROM WorkItems WHERE [System.Parent] = <id>" -o json
```

Relations: `System.LinkTypes.Hierarchy-Forward` = child, `-Reverse` = parent, `System.LinkTypes.Dependency-Reverse` = predecessor, `ArtifactLink` named `Pull Request` = its PR (the ID is the last segment of `vstfs:///Git/PullRequestId/…%2F<pr-id>`).

## Write (only after the user's "go")

Order: Story (if new) → Tasks in dependency order → Predecessor links.

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

A Task: `$Task`, without the two `AcceptanceCriteria` ops.

After the first write, read the item back and check its `multilineFieldsFormat`. If Markdown was rejected, fall back to minimal HTML.

```bash
az boards work-item relation add --id <B> --relation-type predecessor --target-id <A>
```

## PR

Conventions come from the repo's last completed PRs, never from its PR template:

```bash
az repos pr list --status completed --top 5 --query '[].[title, completionOptions.mergeStrategy, completionOptions.deleteSourceBranch]' -o tsv
```

- Title: their pattern, with the Task's ID and title (e.g. `#<task-id>: <task title>`).
- Description: the same short overview on every PR, whatever the repo's PRs do. Plain Markdown for a colleague, readable like the tickets. No template checklist, no checks, no agent scaffolding:
  ````
  <one line: what works after this PR>

  ```text
  <sketch, only if the change spans components: call tree, file tree or data flow, `diff` block if the shape exists; only what matters>
  ```

  **Changes**
  - <what>: <why, if not obvious>

  **Merge danger**: <one-way|two-way> door · blast radius: <who or what breaks if it's wrong>

  <url on the PR's dev namespace: the page that shows the change, else the frontend>

  ![<what it shows>](<attachment url>)
  ````
  One-way: hard to walk back, e.g. a migration, deleted data, a published contract. Blast radius: a few words, e.g. `consumers of <topic>`, `none outside <component>`.
  URL: on every PR whose branch runs on a dev namespace, bare. Screenshot: only for a change a user sees in the UI. It is a PR attachment, so it's uploaded after the PR exists, then the description is updated.
- Annotations: one thread per meaningful hunk, one sentence (what changed + intent), `Autogenerated` on generated files. They stay open: the author never resolves their own annotations.

```bash
az repos pr create --draft --repository <repo> --source-branch <branch> --target-branch <default> \
  --work-items <task-id> <story-id> --title "<title>" --description "$(cat pr.md)"
~/.claude/skills/hitch-tower/hitch-pr annotate <pr> annotations.tsv   # <path>:<line><TAB><text>
curl -s -u ":$AZURE_DEVOPS_EXT_PAT" -H 'Content-Type: application/octet-stream' --data-binary @<png> \
  "$(az repos pr show --id <pr> --query repository.url -o tsv)/pullRequests/<pr>/attachments/<task-id>.png?api-version=7.1" | jq -r .url   # screenshot
az repos pr update --id <pr> --description "$(cat pr.md)"             # keep it true after every push
az repos pr update --id <pr> --draft false                            # publish
az repos pr update --id <pr> --status completed --squash <bool> --delete-source-branch <bool> --transition-work-items false   # as their PRs do
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
