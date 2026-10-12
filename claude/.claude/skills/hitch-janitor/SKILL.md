---
name: hitch-janitor
description: Cleans up after finished work. No argument: this session's leftovers (abandoned approaches, debug code, scratch files) plus a hindsight check. A hitch Story ID: its worktrees and branches, and the temporary code it left on the default branch. Removes debris, reports decisions. Use when the user wants to wrap up or clean up; hitch-tower runs it when a Story is done.
argument-hint: "[story-id]"
---

Remove debris, report decisions: never revert a real decision, never touch the remote or Azure, never `--force` or `-D`.

## Session (no argument)

1. **Scope**: `git status`, `git diff`, this session's commits, and what it made outside the repo (`/tmp` scratch, renders, worktrees, branches).
2. **Remove**:
   - code, files, comments and config flags left from approaches tried and dropped
   - debug output, temp scripts, commented-out code, TODOs the session resolved
   - unused imports and variables; names and idioms that don't match the code around them
   - scratch files outside the repo; merged worktrees and branches it made
3. **Hindsight**: is the final approach still right, or did a late pivot leave scaffolding? Report it, don't rewrite it.

## Story (`<story-id>`)

Repo: the current one unless given. Azure commands: `~/.claude/skills/hitch-clerk/SKILL.md`, read-only.

1. **Local git**: per Task, its worktree under `~/.local/state/hitch/wt/<repo>/` and its local branch. PR completed: `git worktree remove`, `git branch -d`. Dirty or unmerged: report it, leave it.
2. **Remote**: source branches of completed PRs still on origin. Report them.
3. **Leftovers** on `origin/<default>` after `git fetch`:
   - expand/migrate steps whose contract step never landed: shims, dual writes, old columns, compat flags
   - TODO/FIXME naming the Story or its Tasks
   - temporary flags, debug logging, code the Story made unreachable
4. **Azure**: Tasks not `Closed`, the Story's state.

## Report

```
**Removed**: <files, worktrees, branches>
**Leftovers**
- path:line: what → follow-up (Story: a proposed Task, one line)
**For you**
- <item>: <proposed action>
```
