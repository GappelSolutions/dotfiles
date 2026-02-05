# EasyRapport - Time Allocation Generator

Generate time allocation reports from Azure DevOps sprint tasks.

## Usage

```
/easyrapport [sprint_number] [--dates "DD.MM-DD.MM"]
```

## Arguments

- `sprint_number`: Optional. Sprint number to query (e.g., 151, 152). Defaults to current sprint.
- `--dates`: Optional. Date range to allocate hours to (e.g., "07.01-27.01").

## Instructions

You are a time allocation assistant. Follow these steps:

### Step 1: Get Azure DevOps Token

```bash
TOKEN=$(az account get-access-token --resource "499b84ac-1321-427f-aa17-267ca6975798" --query accessToken -o tsv)
```

### Step 2: Get Sprint Info

Query the current or specified sprint iterations:

```bash
curl -s -H "Authorization: Bearer $TOKEN" \
  "https://dev.azure.com/evulutionag/Customer%20Portal/_apis/work/teamsettings/iterations?\$timeframe=current&api-version=7.0"
```

### Step 3: Get Tasks Assigned to User

Query tasks in the sprint assigned to @Me:

```bash
curl -s -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -X POST "https://dev.azure.com/evulutionag/Customer%20Portal/_apis/wit/wiql?api-version=7.0" \
  -d '{"query": "SELECT [System.Id] FROM WorkItems WHERE [System.IterationPath] = '\''Customer Portal\\EB - Sprint NNN'\'' AND [System.AssignedTo] = @Me AND [System.WorkItemType] = '\''Task'\''"}'
```

### Step 4: Get Estimates from Task History

For each task, get the max RemainingWork from revisions (estimates are cleared when Done):

```bash
curl -s -H "Authorization: Bearer $TOKEN" \
  "https://dev.azure.com/evulutionag/Customer%20Portal/_apis/wit/workitems/{id}/revisions?api-version=7.0" \
  | jq '[.value[].fields["Microsoft.VSTS.Scheduling.RemainingWork"] // 0] | max'
```

### Step 5: Get Parent Item for Context

```bash
curl -s -H "Authorization: Bearer $TOKEN" \
  "https://dev.azure.com/evulutionag/Customer%20Portal/_apis/wit/workitems/{id}?\$expand=relations&api-version=7.0" \
  | jq -r '.relations[]? | select(.rel == "System.LinkTypes.Hierarchy-Reverse") | .url'
```

### Step 6: Map Customers to Project IDs

Load mappings from `~/.claude/data/pid-tenant-map.json`:

```bash
cat ~/.claude/data/pid-tenant-map.json | jq '.mappings'
```

Key mappings include:
- **P10053** - All/Allg. (Application Maintenance)
- **P10061** - Arbon
- **P10065** - Horn
- **P10213** - GWB (Gemeindewerke Beckenried)
- **P10214** - Infra ZH (Infrastruktur Zürichsee)
- **P10218** - IBL (IB Langenthal)

Special aliases (from `aliases` in JSON):
- "Arbon + Horn" → split between P10061 and P10065
- "AWU", "Admin GUI" → P10053
- "Backoffice" → P10197

### Step 7: Generate Output

Create a matrix view (Project × Date) and per-date breakdown sorted by PID:

```markdown
## Matrix View (Project × Date)

| Project | DD.MM | DD.MM | ... | TOTAL |
|---------|-------|-------|-----|-------|
| P10053  | Xh    |       |     | Xh    |
...

## Per-Date Breakdown (sorted by PID)

DD.MM (Xh): P10053 Xh (Description), P10XXX Xh (Description)
...
```

### Step 8: Ask User

If user provides a screenshot of open hours, extract the dates and hours per day.
If dates not provided, ask user for the date range and open hours per day.

### Exclusions

Always exclude these projects (user handles separately):
- P10100 (EV - INT - Sitzungen)
- P10103 (EB - INT - Sitzungen)
- P10128 (EA - INT - EASYASSET 2.0)

### Output File

Save to `~/dev/time-allocation-{month}{year}.md` and provide the path for user to open in nvim.
