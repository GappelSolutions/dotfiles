# Commit Workflow

Smart commit workflow that adapts to project settings.

## Step 1: Check for Project-Specific Settings

First, check if a `.claude/commit-config.md` file exists in the current git repository root:

```bash
git rev-parse --show-toplevel
```

Then read `.claude/commit-config.md` from that location if it exists.

**If project-specific config exists:** Follow those instructions instead of the default workflow below.

**If no project-specific settings:** Continue with detection below.

---

## Step 2: Detect Project Type

Check the git remote to determine which workflow to use:

```bash
git remote get-url origin
```

**If remote contains `ea-angular-frontend` or `ea-dot-net-authentication`:** Use the **EasyAsset Workflow (GitHub, English)** below.

**Otherwise:** Use the **Default Workflow (Azure DevOps, German)** below.

---

## EasyAsset Workflow (GitHub, English)

For EasyAsset projects hosted on GitHub.

### Step 1: Gather Information

Use AskUserQuestion to ask the user for the following:

1. **Base Branch** - Which branch to base off (options: development, main)
2. **Branch Type** - Type of change (options: feat, bug, hotfix, chore)
3. **Ticket ID** - Work item ID (user enters via "Other", can be left empty)

### Step 2: Prepare Branch

```bash
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
git add -A

git commit -m "$(cat <<'EOF'
<type>(<component>): <description>

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

### Step 4: Push and Create PR (GitHub)

```bash
git push -u origin <branch-name>

# Create PR targeting development (descriptions in ENGLISH!)
gh pr create \
  --base development \
  --head <branch-name> \
  --title "<type>(<component>): <title>" \
  --body "$(cat <<'EOF'
## Summary
- <English summary of changes>

## Test plan
- [ ] <English test steps>
EOF
)"

# Open PR in browser
gh pr view --web
```

### EasyAsset Rules

- PR descriptions MUST be in **English**
- Use `gh pr create` (GitHub CLI), NOT `az repos pr create`
- Target branch is typically `development`
- Do NOT include "Generated with Claude Code" in PR description

---

## Default Workflow (Azure DevOps, German)

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

### Azure DevOps Rules

- PR descriptions MUST be in **German**
- Use `az repos pr create` (Azure CLI)
- Link the work item after creating PR (only if ticket ID provided)
- Branch naming: `TYPE/TICKET_ID-description` or `TYPE/description` (no ticket)
- Commit format: `#TICKET_ID TYPE(component): description` or `TYPE(component): description` (no ticket)
- Do NOT include "Generated with Claude Code" in PR description
- Target branch for PRs is always `dev`
