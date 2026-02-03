# Azure DevOps Ticket Context

Fetch full context for Azure DevOps work items including related items, PRs, commits, attachments, and comments.

## Arguments

- `$ARGUMENTS` - One or more ticket IDs (space or comma separated), e.g., "22648" or "22648, 22656"

## Workflow

### Step 1: Parse Ticket IDs

Extract ticket IDs from the arguments. Support formats:
- Single: `22648`
- Multiple: `22648 22656` or `22648, 22656`

If no ticket IDs provided, ask the user for them.

### Step 2: Fetch Each Ticket

For each ticket ID, gather the following information:

#### 2.1 Work Item Details

```bash
az boards work-item show --id <TICKET_ID> --expand all -o json
```

Extract and display:
- **ID & Title**: `System.Id`, `System.Title`
- **Type**: `System.WorkItemType` (PBI, Bug, Task, etc.)
- **State**: `System.State`
- **Assigned To**: `System.AssignedTo.displayName`
- **Area Path**: `System.AreaPath`
- **Iteration**: `System.IterationPath`
- **Description**: `System.Description` (HTML - strip tags for readability)
- **Acceptance Criteria**: `Microsoft.VSTS.Common.AcceptanceCriteria` (if present)
- **Priority**: `Microsoft.VSTS.Common.Priority`
- **Created/Changed**: `System.CreatedDate`, `System.ChangedDate`

#### 2.2 Parse Relations

From the `relations` array, categorize by `rel` type:

**Work Item Links:**
- `System.LinkTypes.Hierarchy-Reverse` → Parent
- `System.LinkTypes.Hierarchy-Forward` → Children
- `System.LinkTypes.Related` → Related Items
- `System.LinkTypes.Dependency-Forward` → Successors
- `System.LinkTypes.Dependency-Reverse` → Predecessors

For each linked work item, extract the ID from the URL (last segment) and fetch basic info:
```bash
az boards work-item show --id <LINKED_ID> --fields "System.Id,System.Title,System.State,System.WorkItemType" -o json
```

**Artifact Links:**
- `ArtifactLink` with `name: "Pull Request"` → PRs
- `ArtifactLink` with `name: "Fixed in Commit"` or `name: "Branch"` → Commits/Branches

**Attachments:**
- `AttachedFile` → File attachments (extract URL for download)

**Hyperlinks:**
- `Hyperlink` → External links

#### 2.3 Fetch PR Details

For each PR link, extract the PR ID from the URL pattern:
`vstfs:///Git/PullRequestId/{project}%2F{repo}%2F{prId}`

```bash
az repos pr show --id <PR_ID> -o json
```

Display:
- PR ID, Title, Status
- Source → Target branch
- Created by, Creation date
- Merge status
- Reviewers and their votes

#### 2.4 Fetch Comments

```bash
az devops invoke --area wit --resource comments --api-version 7.0-preview \
  --route-parameters project="Customer Portal" workItemId=<TICKET_ID> -o json
```

Display each comment with author and date.

### Step 3: Output Format

Present the information in a clear, structured format:

```markdown
## Ticket #<ID>: <Title>

**Type:** <WorkItemType> | **State:** <State> | **Priority:** P<Priority>
**Assigned:** <AssignedTo> | **Iteration:** <Iteration>
**Area:** <AreaPath>

### Description
<Description text, cleaned of HTML>

### Acceptance Criteria
<If present>

---

### Related Work Items

#### Parent
- #<ID> <Title> (<State>)

#### Children
- #<ID> <Title> (<State>)
- ...

#### Related
- #<ID> <Title> (<State>)

---

### Pull Requests

#### PR #<ID>: <Title>
- **Status:** <status> | **Merge:** <mergeStatus>
- **Branch:** <source> → <target>
- **Created:** <date> by <author>
- **Reviewers:** <reviewer> (<vote>), ...

---

### Commits
- `<short-hash>` <message> (from PR description or commit link)

---

### Attachments
- [<filename>](<url>) - <size if available>

---

### Comments
**<author>** (<date>):
> <comment text>

---

### Links
- [Azure DevOps](https://dev.azure.com/evulutionag/Customer%20Portal/_workitems/edit/<ID>)
```

### Step 4: Multiple Tickets

If multiple ticket IDs provided, repeat the above for each, with clear separation between tickets.

## Helper: Extract Work Item ID from URL

Work item URLs look like:
`https://dev.azure.com/evulutionag/{project}/_apis/wit/workItems/{id}`

Extract the last path segment as the ID.

## Helper: Extract PR ID from Artifact URL

PR artifact URLs look like:
`vstfs:///Git/PullRequestId/{projectGuid}%2F{repoGuid}%2F{prId}`

URL-decode and extract the last segment as the PR ID.

## Helper: Clean HTML

Strip HTML tags from description fields for readability. Keep the text content.

## Notes

- If a ticket doesn't exist, report the error and continue with other tickets
- If PRs or comments API calls fail, note the failure but continue with available data
- For attachments, provide the URL - the user can download manually or you can use WebFetch if needed
- Always include the direct Azure DevOps link for easy browser access
