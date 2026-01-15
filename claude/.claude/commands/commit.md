# Commit & PR Workflow

Create a branch, commit changes, and open a PR following project conventions.

## Workflow

Execute this workflow step by step:

### Step 1: Gather Information

Use AskUserQuestion to ask the user for the following:

1. **Base Branch** - Which branch to base off (options: dev, stage, master)
2. **Branch Type** - Type of change (options: feat, bug, hotfix, chore)
3. **Short Description** - Brief kebab-case description for branch name (user enters via "Other")
4. **Ticket ID** - Azure DevOps work item ID (user enters via "Other", can be left empty)

### Step 2: Prepare Branch

```bash
# Fetch latest and checkout base branch
git fetch origin
git checkout <base-branch>
git pull origin <base-branch>

# Create feature branch
# With ticket: TYPE/TICKET_ID-description
# Without ticket: TYPE/description
git checkout -b <type>/<ticket-id>-<description>
# OR if no ticket:
git checkout -b <type>/<description>
```

### Step 3: Stage and Commit

Run git status and git diff to see changes, then:

```bash
# Stage all changes
git add -A

# Commit with convention
# With ticket: #TICKET_ID TYPE(component): description
# Without ticket: TYPE(component): description
git commit -m "$(cat <<'EOF'
#<ticket-id> <type>(<component>): <description>

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

For the component, infer from the changed files (e.g., "quick-links", "settings", "auth").

### Step 4: Push and Create PR

```bash
# Push branch
git push -u origin <branch-name>

# Create PR targeting dev (descriptions in German!)
az repos pr create \
  --source-branch <branch-name> \
  --target-branch dev \
  --title "<title>" \
  --description "$(cat <<'EOF'
## Zusammenfassung
- <German summary of changes>

## Testplan
- [ ] <German test steps>
EOF
)"
```

Title format:
- With ticket: `#TICKET_ID TYPE(component): title`
- Without ticket: `TYPE(component): title`

### Step 5: Link Work Item (if ticket provided) and Open PR

```bash
# Get PR ID from create output, then link work item (only if ticket ID was provided)
az repos pr work-item add --id <PR_ID> --work-items <ticket-id>

# Open PR in browser
az repos pr show --id <PR_ID> --open
```

## Important Rules

- PR descriptions MUST be in German
- Link the work item after creating PR (only if ticket ID provided)
- Branch naming: `TYPE/TICKET_ID-description` or `TYPE/description` (no ticket)
- Commit format: `#TICKET_ID TYPE(component): description` or `TYPE(component): description` (no ticket)
- Do NOT include "Generated with Claude Code" in PR description
- Target branch for PRs is always `dev`
