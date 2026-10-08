---
name: hitch-pilot
description: Release the default branch to stage with zero downtime. Reviews every change since the last release, anyone's, for what breaks while old and new versions run side by side, and opens the release PR with the checklist the release needs. Use when the user wants to cut, prepare or check a release.
argument-hint: "[repo]"
---

# hitch-pilot

The standard: zero downtime, every release. You find what would break it before the release PR merges. Many PRs aren't hitch PRs: a missing Merge danger line or `after:` item means nothing, the diff is the source of truth.

Input: `$ARGUMENTS`

## Output rules

- No bloat: keywords, bullets, one line per fact.
- The release PR is read by colleagues: plain Markdown, no agent scaffolding.
- `#flag <note>` from the user marks a moment for `hitch-inspector`. Reply `noted` and carry on.

## Start

1. Load the `hitch-clerk` skill. `hitch-pr` means `~/.claude/skills/hitch-tower/hitch-pr`. Repo: the input, else the current one.
2. Branches: `<dev>` = the default branch. `<release>` = the branch whose pipelines deploy stage (repo CLAUDE.md, pipeline triggers). Unclear: ask once.
3. `git fetch origin`. Range: `git log --first-parent origin/<release>..origin/<dev>`. Empty: say so, stop.
4. Units, one per first-parent commit:
   - `Merged PR <n>`: the PR. `az repos pr show --id <n>`: description (Merge danger, if any), linked Tasks' `after:` lines.
   - A merge of `<release>` into `<dev>` (second parent already in `origin/<release>`): skip, stage has it.
   - Anything else: a direct commit, its own unit.
5. An active `<dev>` → `<release>` PR already: that's the release PR. Review again and update it, never a second one.

## Rollout mechanics

Before review, read how a deploy runs, from the pipelines and deployment definitions of every service the range touches. One line each, with `path:line`:
- when migrations run, relative to the rollout
- rollout strategy (`Recreate` = downtime) and replicas on stage
- readiness probes, graceful shutdown
- whether services deploy in a fixed order or in parallel
- what a frontend deploy does to open browser sessions

This is the reviewers' brief. A standing hazard (e.g. `Recreate`) goes in every release that deploys that service.

## Review

Batch the units by service (the paths their diffs touch), ≤10 per batch, dependency and lockfile bumps together in one. Per batch, one `general-purpose` agent (opus · high) in the background: the mechanics brief, its units (sha, PR, title, description, `after:` lines), the lens below, `git diff <sha>^1 <sha>` per unit. Read-only: never edits, never touches Azure. Report per unit `clean`, or per hazard `<what breaks> · <when in the rollout> · <fix>` with `path:line`.

Lens. N = this release, N-1 = what stage runs now. During the release both run at once, next to data N-1 already wrote:
- **Schema**: a migration live while N-1 runs: dropped or renamed column/table, NOT NULL without default, changed type, a constraint N-1 violates. Long lock or table rewrite at stage volume.
- **Contracts** between services, in any deploy order: message shape, exchange/queue/routing key names, enum values on the wire or persisted, API routes and fields. N-1 reading N's messages and the other way round, messages already queued in N-1's format.
- **Frontend**: open browsers on the N-1 SPA calling the N API.
- **Persisted formats**: cache keys, serialized blobs, files, job payloads N-1 stored.
- **Config**: a new env var, secret, vault key or flag that must exist on stage before the pods start; a removed one N-1 still reads.
- **Workers**: scheduled jobs run twice or skipped across the switch, single replica, shutdown without draining (in-flight work lost), startup slower than the readiness probe allows.
- **Cutovers**: a service replaced or removed, a port or route moved: what still sends to the old one during the switch.
- **External**: anything outside the cluster that sees the change (devices, partners, firewalls).

Then you, across all reports:
- Cross-unit hazards: a contract change and its consumer in different services (deploy order), an expand and its contract both in range, two migrations on one table.
- Open the cited `path:line` yourself for every blocker before it goes in.

## Checklist

Show the user, empty sections dropped:

```
**Release <dev> → <release>**: <n> PRs, <n> direct commits · <base-sha>..<head-sha>
**Blockers**: downtime as is
- PR <n> <title>: <what breaks, when> (`path:line`) → <fix: follow-up PR on <dev> | revert | hold the release>
**Before deploy**
- <secret, config or flag to set on stage>
**Order**
- <service> before <service>: <why>   (only if the pipelines don't already ensure it)
**Migrations**
- PR <n>: <table: op> · N-1 safe · <lock/duration at stage volume>
**Standing**
- <service>: <hazard every release has>
**After deploy**
- <`after:` items, what to check on stage>
**Clean**: PR <n>, <n>, …
```

Blockers are the user's call: fix on `<dev>` first (`hitch-duck`/`hitch-tower`, or by hand), or release anyway. No release PR with an open blocker unless the user says so.

## Release PR (on the user's OK)

Title, and whether it's a draft, from the last release PRs:

```bash
az repos pr list --status completed --source-branch <dev> --target-branch <release> --top 3 --query '[].[title, isDraft]' -o tsv
az repos pr create --repository <repo> --source-branch <dev> --target-branch <release> --title "<title>" --description "$(cat release.md)"
```

Description: the checklist. Azure caps it at 4000 chars: over that, **Clean** becomes a count, then the rest moves to a PR comment (threads endpoint in `hitch-clerk`). Existing release PR: `az repos pr update --id <pr> --description …`.

Never complete it: when to release is the team's call.

## Wait

Run `hitch-pr wait <pr>` in the background. It exits on a push, vote, status or comment change. Then:
- **Push** (new commits on `<dev>`): Review the new units only, update the description, say what changed.
- **Comments** from others: one line each, plus a proposed reply. Post nothing without the user's OK.
- **Completed**: a `hitch-gofer` runs step 1 of **After merge** in `hitch-clerk` for the merge commit on `<release>`: every stage pipeline run until it finishes. Report one line per pipeline; a failure goes to the user. Then done.
- **Abandoned**, or the user says stop: stop. Otherwise restart the wait.
- A user message cuts the wait short: check the PR right away.
