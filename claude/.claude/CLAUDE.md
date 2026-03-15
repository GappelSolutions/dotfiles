# Dotfiles & Stow

The `~/.claude` directory is symlinked from `~/dev/dotfiles/claude/.claude` via GNU Stow. When editing Claude configuration files (CLAUDE.md, commands, settings), **always edit the dotfiles version** at `~/dev/dotfiles/claude/.claude/` - changes will automatically apply to `~/.claude` via the symlink.

# Nix / Home-Manager

The dotfiles use nix-darwin and home-manager for system configuration. Location: `~/dev/dotfiles/nix/`

## CRITICAL: New Files Must Be Git-Tracked

**Before running `rebuild`, any NEW files must be added to git:**
```bash
git add path/to/new/file
```

Nix uses a flake that only sees git-tracked files. If you create a new file (script, config, etc.) and run `rebuild` without `git add`, you'll get:
```
error: Path 'path/to/file' in the repository is not tracked by Git.
```

**Workflow for adding new files to nix config:**
1. Create the file
2. `git add path/to/new/file` (stage it)
3. `rebuild` (now nix can see it)
4. Test
5. Commit when ready

## Zellij Session Shortcuts

Quick session launchers (attach to active or create new):
- `zeb` - Energyboard
- `zbo` - Backoffice
- `zea` - EasyAsset
- `zex` - Elixir
- `zgs` - Gappel Solutions
- `zdc` - Decon
- `zsc` - Screensaver
- `zlc` - Lazychat

Sessions are named `LAYOUT-TIMESTAMP` (e.g., `elixir-20260202-131805`). Only attaches to active sessions, never resurrects exited ones.

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

# Jujutsu (jj) - Preferred Over Git

**IMPORTANT:** When a repo has jj initialized (`.jj/` directory exists), prefer jj commands over git.

## Why jj Over Git

- **Auto-commit**: Working copy is always tracked, impossible to lose work
- **Undo anything**: `jj undo` reverses any operation
- **Lock-free parallel**: Multiple workspaces on same repo simultaneously
- **Git-compatible**: Full interop, `jj git push` works with GitHub/Azure DevOps

## Detecting jj Repos

```bash
# Check if jj is initialized
if [ -d ".jj" ]; then
  echo "Use jj commands"
else
  echo "Use git commands"
fi
```

## jj Command Reference

| Git Command | jj Equivalent | Notes |
|-------------|---------------|-------|
| `git status` | `jj status` | Shows working copy changes |
| `git log` | `jj log` | Shows commit graph |
| `git add . && git commit -m "msg"` | `jj describe -m "msg"` | Working copy auto-tracks |
| `git checkout -b branch` | `jj new -m "description"` | Creates new change |
| `git branch branch-name` | `jj bookmark create branch-name` | Bookmarks are jj's branches |
| `git push origin branch` | `jj git push --bookmark branch` | Push specific bookmark |
| `git pull` | `jj git fetch && jj rebase -d main@origin` | Fetch + rebase |
| `git diff` | `jj diff` | Show changes |
| `git stash` | Not needed | Working copy is always a commit |

## jj PR Workflow

```bash
# 1. Start work (already on main)
jj new -m "feat: add login page"

# 2. Make changes... (auto-tracked, no git add needed)

# 3. Create bookmark (branch) for PR
jj bookmark create feat/12345-add-login

# 4. Push bookmark
jj git push --bookmark feat/12345-add-login

# 5. Create PR via CLI
az repos pr create \
  --source-branch feat/12345-add-login \
  --target-branch dev \
  --title "#12345 feat(auth): add login page"

# 6. If PR needs changes
jj edit <change-id>  # Go back to that change
# Make fixes...
jj git push --bookmark feat/12345-add-login  # Force-pushes automatically
```

## Common jj Patterns

```bash
# See what I'm working on
jj log

# Update commit message
jj describe -m "better message"

# Undo last operation (SAFE - works for anything)
jj undo

# Split current change into multiple commits
jj split

# Squash into parent
jj squash

# Rebase onto latest main
jj git fetch
jj rebase -d main@origin
```

## When to Still Use Git

- Repo doesn't have `.jj/` initialized
- Complex merge conflict resolution (jj defers conflicts)
- Team requires specific git workflow

**Language Rules:**
- Branch names: **English** (e.g., `feat/12345-add-dark-mode`)
- Commit messages: **English** (e.g., `#12345 feat(admin): add previous user menu`)
- PR titles: **English** (e.g., `#12345 feat(admin): add previous user menu`)
- PR descriptions: **German** (Zusammenfassung, Testplan)

**Other Rules:**
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

## Seq Logging (Dev)

Both EasyAsset and Customer Portal (EnergyBoard) log to the same local Seq instance:
- **URL**: http://localhost:5341
- **API Key**: `wUc2lqD0zQ7vlR5W0jdu`
- **Admin password**: `admin`
- Filter by `Application == 'EasyAsset'` or `Application == 'EnergyBoard'`

Use `curl` to check logs when debugging backend issues:
```bash
# Query recent errors
curl -s "http://localhost:5341/api/events?filter=@Level%3D'Error'" -H "X-Seq-ApiKey: wUc2lqD0zQ7vlR5W0jdu" | jq
# Filter by app
curl -s "http://localhost:5341/api/events?filter=Application%3D'EasyAsset'" -H "X-Seq-ApiKey: wUc2lqD0zQ7vlR5W0jdu" | jq
```

# Cloud Server (Home Server)

- **Host**: `cloud` (resolves to `192.168.178.33` on local network)
- **SSH User**: `cgpp`
- **Auth**: Password-based (ask user for password before connecting)
- **Access**: `sshpass -p '<password>' ssh -o StrictHostKeyChecking=accept-new cgpp@cloud "<command>"`

When SSH access is needed, always prompt the user for the password first. Do not assume or store the password.

The server runs Docker containers for private projects (e.g., berp/ConstructSync with MariaDB).

## Browser Agent Tips for Portal

1. **Dropdowns appear as empty buttons** in snapshot - look for `button ""` refs
2. **Search boxes** often appear after clicking dropdowns - wait and re-snapshot
3. **Tenant switch requires re-login** - credentials work across all tenants
4. **Wait after navigation** - use `wait 3000` after major actions like login or subject selection
5. **Screenshots help** - when snapshot doesn't show expected elements, take a screenshot to see the actual UI state
6. **Cookie banner** - may need to dismiss with `click "text=Confirm"` on first visit
