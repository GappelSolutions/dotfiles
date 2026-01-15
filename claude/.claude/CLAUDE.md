# Test Credentials

For testing the customer portal locally (works for all tenants):
- **URL**: http://localhost:4200
- **Email**: christian.gappel@evulution.com
- **Password**: ASDQWEasdqweASDQWE123

# AI Agent Browser Access

You have access to `agent-browser`, a headless browser CLI that lets you interact with web pages and get visual feedback.

## IMPORTANT: Use This Proactively

**You SHOULD use agent-browser automatically when:**
- You've made frontend/UI changes and need to verify they work
- The user reports a visual bug - see it yourself before guessing
- You're unsure what a page looks like - take a screenshot
- Testing forms, buttons, or interactive elements
- The user asks you to "check" or "test" something in a browser

**Don't wait to be asked.** If you're working on web UI and can verify your changes visually, do it.

## Quick Reference

### Basic Workflow

```bash
# 1. Open a page
agent-browser open https://example.com

# 2. Get a snapshot of interactive elements (RECOMMENDED for AI)
agent-browser snapshot -i --json

# 3. Interact using element refs from snapshot (@e1, @e2, etc.)
agent-browser click @e3
agent-browser fill @e5 "search query"

# 4. Take a screenshot to see the result
agent-browser screenshot /tmp/result.png

# 5. Close when done
agent-browser close
```

### Essential Commands

| Command | Description |
|---------|-------------|
| `open <url>` | Navigate to a webpage |
| `snapshot -i` | Get accessibility tree with element refs (interactive only) |
| `snapshot -i --json` | Same but machine-readable |
| `click <selector>` | Click an element |
| `fill <selector> <text>` | Clear and type into input |
| `type <selector> <text>` | Type without clearing |
| `screenshot [path]` | Capture viewport |
| `screenshot --full [path]` | Capture full page |
| `get text <selector>` | Extract text from element |
| `get url` | Get current URL |
| `wait <selector>` | Wait for element to appear |
| `wait <ms>` | Wait milliseconds |
| `close` | Close browser session |

### Selectors

**Element refs (from snapshot):** `@e1`, `@e2`, etc. - Most reliable for AI use

**CSS selectors:** `"#id"`, `".class"`, `"button.submit"`

**Text-based:** `"text=Click me"`

### Multi-Session

Run multiple isolated browsers:
```bash
agent-browser --session test1 open https://site-a.com
agent-browser --session test2 open https://site-b.com
agent-browser --session test1 click @e2
```

### Useful Options

- `--headed` - Show visible browser window (for debugging)
- `--json` - Machine-readable output
- `--full` - Full page screenshot

## Example: Test a Login Flow

```bash
# Open login page
agent-browser open https://myapp.com/login

# See what's on the page
agent-browser snapshot -i

# Fill credentials (use refs from snapshot)
agent-browser fill @e3 "user@example.com"
agent-browser fill @e5 "password123"

# Click login
agent-browser click @e7

# Wait for redirect and verify
agent-browser wait 2000
agent-browser get url
agent-browser screenshot /tmp/after-login.png

# Clean up
agent-browser close
```

## Tips for AI Agents

1. **Always use `snapshot -i`** to discover element refs - don't guess selectors
2. **Take screenshots** after important actions to verify state
3. **Use `--json`** when parsing output programmatically
4. **Close the browser** when done to free resources
5. **Use sessions** if you need multiple browsers simultaneously

# Git Conventions

## Branch Naming
```
TYPE/TICKET_ID-short-description
```
Examples:
- `feat/12345-add-dark-mode`
- `bug/12346-fix-login-redirect`
- `hotfix/12348-critical-auth-fix`
- `chore/12347-cleanup-dependencies`

Types: `feat`, `bug`, `hotfix`, `chore`

## Commit Messages
```
#TICKET_ID TYPE(component): description
```
Examples:
- `#12345 feat(consumption): add hydrological calendar support`
- `#12346 bug(auth): resolve login redirect loop`
- `#12347 chore(deps): update angular to v19`

Types: `feat`, `bug`, `chore` (hotfix branches use `bug` in commit)

## Lazygit Workflow

The user uses lazygit for git operations. Key commands:
- **`o`** on a commit/branch: Opens in Azure DevOps browser (creates PR or views commit)
- **`P`**: Push to remote
- **`p`**: Pull from remote
- **`c`**: Commit staged changes

When the user says "press o in lazygit", they're opening the branch/commit in Azure DevOps to create a Pull Request.

## Creating PRs with Azure DevOps CLI

PRs go to `dev` branch. Always create a feature/bug branch first:

```bash
# 1. Create and push branch
git checkout -b bug/TICKET_ID-description
git push -u origin bug/TICKET_ID-description

# 2. Create PR
az repos pr create \
  --repository CustomerPortal.Angular \
  --source-branch bug/TICKET_ID-description \
  --target-branch dev \
  --title "#TICKET_ID bug(component): description" \
  --description "## Summary
- What was fixed/added

## Test plan
- [ ] Test steps"

# 3. Link work item (required!)
az repos pr work-item add --id PR_ID --work-items TICKET_ID
```

**Important:**
- PR descriptions must be in **German**
- Do NOT include "Generated with Claude Code" or similar in PR descriptions
- Always link the work item using `az repos pr work-item add`
- Direct pushes to `dev` are blocked; must use PR

# Customer Portal Navigation Guide

## Portal Structure

The Customer Portal is a multi-tenant Angular application. Key concepts:
- **Tenant**: Each energy company (EVULUTION, GLATTWERK, etc.) is a separate tenant with its own theme/branding
- **Subject**: A customer account identified by Subject-ID (e.g., 70863)
- **Admin view**: Available for admin users, accessed at `/admin/dashboard`

## Switching Tenants (Dev Mode)

The **`</>`** button in the top-right corner opens the dev dropdown:

1. Click the `</>` icon (may need coordinates: `mouse move 1185 35 && mouse down && mouse up`)
2. Open "Tenant Selector" dropdown and search for tenant name
3. Select tenant - **this logs you out**
4. Log in again with the same credentials

**Note**: Different tenants have different themes (EVULUTION = purple, GLATTWERK = green)

## Selecting a Subject

After login, you land on admin dashboard. To view customer data:

1. Click the subject selector dropdown (shows "Auswählen" or "Select")
2. Search by Subject-ID or customer name in the search box
3. Click to select - navigates to customer dashboard

## Portal Pages

| Path | Description |
|------|-------------|
| `/login` | Login page |
| `/admin/dashboard` | Admin landing page with subject selector |
| `/dashboard` | Customer dashboard (after subject selection) |
| `/verbrauch-kosten` or `/consumption` | Consumption & costs page |
| `/rechnungen` or `/invoices` | Invoices page |

## Browser Agent Tips for Portal

1. **Dropdowns appear as empty buttons** in snapshot - look for `button ""` refs
2. **Search boxes** often appear after clicking dropdowns - wait and re-snapshot
3. **Tenant switch requires re-login** - credentials work across all tenants
4. **Wait after navigation** - use `wait 3000` after major actions like login or subject selection
5. **Screenshots help** - when snapshot doesn't show expected elements, take a screenshot to see the actual UI state
6. **Cookie banner** - may need to dismiss with `click "text=Confirm"` on first visit
