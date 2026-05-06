# Vault Cleanup

Clean up completed task folders from the codelayer vault for the current project.

## Project Detection

```bash
basename $(git rev-parse --show-toplevel 2>/dev/null || pwd)
```
Use this as `{project}` in vault paths: `~/dev/codelayer-vault/{project}/`

## Process

1. **List all task folders** in `~/dev/codelayer-vault/{project}/`
2. **For each folder**, quickly assess status:
   - Read the plan file(s) inside
   - Check git log for commits referencing the task name or ticket ID
   - Check if a related branch exists (`git branch -a --list "*TASKNAME*"`)
   - Classify as: **implemented** (evidence in git), **in-progress** (partial commits or active branch), or **unknown** (no git evidence found)
3. **Present a summary table**:
   ```
   Vault Cleanup - {project}

   IMPLEMENTED (safe to delete):
   - taskname-1/ - commits found, branch merged
   - taskname-2/ - commits found in main

   IN PROGRESS (keep):
   - taskname-3/ - active branch exists

   UNKNOWN (needs manual decision):
   - taskname-4/ - no git evidence found
   ```
4. **Ask once**: "Delete the IMPLEMENTED folders? (y/n) Any UNKNOWN folders you also want removed?"
5. **Delete confirmed folders** with `rm -rf`
6. **Report** what was cleaned up

## Guidelines

- Be fast. Skim plans for ticket IDs and task names, check git - don't deep-analyze anything.
- When in doubt, classify as UNKNOWN rather than guessing.
- Never delete IN PROGRESS folders without explicit confirmation.
- If the vault directory for this project doesn't exist or is empty, just say so.
