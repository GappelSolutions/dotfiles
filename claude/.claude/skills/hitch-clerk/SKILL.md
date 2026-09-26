---
name: hitch-clerk
description: Azure DevOps conventions and commands for the hitch workflow (hitch-duck, hitch-tower). Covers the shape of Features, User Stories, Tasks, blocking links and PR links, and when a Story is ready. Load it when a hitch skill reads or writes work items, or when a hitch ticket is fixed by hand.
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

**Ready** means (this is the `hitch-tower` gate): a goal line, acceptance criteria, resolvable decision refs, checks, and every Predecessor `Closed`.

## Read

```bash
az boards work-item show --id <id> --expand all -o json   # fields + relations
az boards query --wiql "SELECT [System.Id] FROM WorkItems WHERE [System.Parent] = <id>" -o json
```

Relations: `System.LinkTypes.Hierarchy-Forward` = child, `-Reverse` = parent, `System.LinkTypes.Dependency-Reverse` = predecessor.

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
