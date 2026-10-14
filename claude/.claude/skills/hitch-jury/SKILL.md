---
name: hitch-jury
description: "Review a PR with the hitch review crew only, sized to its risk: one hitch-skeptic, or two blind ones and a hitch-referee on top. Someone else's: proposes review comments and a vote, posts them on your OK, re-reviews after the author pushes. Your own: applies every fix and pushes. No PR given: lists the active PRs where you're a reviewer. Start it only when the user or a hitch skill asks."
argument-hint: "[pr-id | pr-url]"
---

# hitch-jury

You review a colleague's PR for the user. You don't write code and never push to their branch.

Input: `$ARGUMENTS`

## Output rules

- No bloat: keywords, bullets, one line per fact.
- Comments you post: one line, `<what's wrong> → <fix>`. Keywords, symbols and code in backticks, ≤ ~150 chars. The fix is one concrete change, never "consider"; no fix known: the problem alone. Nothing else: no greeting, no severity tag, no summary, never a mention of AI or reviewers A/B. Language: the one the PR's discussion already uses, else the PR description's.
- `#flag <note>` from the user marks a moment for `hitch-inspector`. Reply `noted` and carry on.

## Start

1. Load the `hitch-clerk` skill. `hitch-pr` means `~/.claude/skills/hitch-tower/hitch-pr`. Your ID, to spot your vote and threads:
   ```bash
   id=$(curl -s -u ":$AZURE_DEVOPS_EXT_PAT" "$org/_apis/connectionData" | jq -r .authenticatedUser.id)
   ```
2. No input: the active PRs where you're a reviewer, in every project (`az repos pr list` only sees the default one). Show `| PR | repo | title | author | my vote | draft |` and ask which. A PR URL: its last path segment is the ID.
   ```bash
   curl -s -u ":$AZURE_DEVOPS_EXT_PAT" "$org/_apis/git/pullrequests?searchCriteria.reviewerId=$id&searchCriteria.status=active&api-version=7.1"
   ```
3. Load the PR:
   - `az repos pr show --id <pr> -o json`: repo, source and target branch (`refs/heads/` stripped), author, reviewers.
   - Threads, as in `hitch-clerk`: what's already been said, and which threads are yours (first comment's `author.id` = `$id`).
   - Brief: the linked work items (`az repos pr work-item list --id <pr>`). A Task: its scope, plus its parent Story. A Story: its description, ACs and `## Design` if it has one. None: the PR title and description.
4. **Your own PR** (author = `$id`): no comments, no vote. The Fix list gets applied instead: worktree on the branch itself (`git -C <clone> worktree add <wt> <source>`), Review as below, then a `hitch-mechanic` with the worktree, the brief and the whole Fix list (tier `none`: nothing to apply), in a slot as in `hitch-tower`'s Crew. It applies, runs the checks, and you `git push` (never force) and sync the description and annotations as in `hitch-clerk`. Show what was applied and the **Open** items. No follow-up wait: done.
5. Worktree: find a local clone whose `origin` points at the PR's repo (the current repo, else `find ~/dev -maxdepth 4 -name .git`). None: ask the user.
   ```bash
   git -C <clone> fetch origin <source> <target>
   git -C <clone> worktree add --detach ~/.local/state/hitch/wt/<repo>/pr-<pr> origin/<source>
   ```
   It already exists (a later session): `git -C <wt> checkout --detach origin/<source>` after the fetch.

## Review

The crew is the whole review: no other review agents.

1. **Tier** by hitch-tower's Review step (`~/.claude/skills/hitch-tower/SKILL.md`, Loop step 4), from `git -C <wt> diff --stat origin/<target>...HEAD`, stated in one line with the reason. Input: the worktree, `origin/<target>` as base, the brief, the open threads (drop a finding someone already raised there). No hand-off: the author wrote it.
   - `none`: no agents, propose `approve`.
   - `one`: one `hitch-skeptic` in the background. Its findings are the comments.
   - `full`: two `hitch-skeptic` runs in the background, in parallel, neither sees the other, B with the model override `sonnet` (trial, measured by `hitch-inspector`), each writing to `/tmp/hitch-pr-<pr>/review-<A|B>.md`. Then `hitch-referee` with the same input plus both files.
2. `git -C <wt> update-ref refs/hitch/pr-<pr>/base origin/<target>` and `refs/hitch/pr-<pr>/reviewed HEAD`.
3. Show:
   ```
   **PR <pr> <title>** by <author>
   - does: <one line, from the diff>
   - verdict: <proposed vote> · <n> comments · <n> dropped
   **Comments**
   1. path:line: <the text you'd post>   e.g. `meter` null on cache miss, NRE in `StoreAsync` → `if (meter is null) return Results.NotFound();`
   **Open** (for you)
   - <question>
   ```
   Proposed vote: `wait-for-author` if any comment is a blocker, `approve-with-suggestions` if only fixes, `approve` if none. Never `reject` unless the user says so.

## Post (only on the user's OK)

The user may drop, edit or add comments first. Post exactly what they approved:

```bash
hitch-pr annotate <pr> comments.tsv                  # <path>:<line><TAB><text>, one thread each
az repos pr set-vote --id <pr> --vote <vote>
```

A comment for the whole PR: POST to the threads endpoint (`hitch-clerk`) with `{"status": "active", "comments": [{"parentCommentId": 0, "content": "…", "commentType": 1}]}`.

## Follow-up

Run `hitch-pr wait <pr>` in the background. It exits on a push, vote, status or comment change. Then:

- **Replies** in your threads: one line each, plus a proposed answer. Post nothing without the user's OK.
- **Push**: fetch, move the worktree to the new `origin/<source>`. Review only the new part, by hitch-tower's Reruns rule: `refs/hitch/pr-<pr>/reviewed..HEAD`, after a rebase or a merge of the target only what `git range-diff` marks changed plus conflict resolutions. Your open threads go along: per thread `addressed` (path:line shows it) or `not` (why); at tier `none` you check them yourself in that diff. Move both refs. Propose: `fixed` for addressed threads, for the rest a one-line reply (why it still holds, or why the author's reply doesn't), new comments only for new code, and the new vote.
- **Completed or abandoned**, or the user says stop: `git -C <clone> worktree remove <wt>`, `git -C <clone> update-ref -d` both `refs/hitch/pr-<pr>/*`, and report. Otherwise restart the wait.
- A user message cuts the wait short: check the PR right away.

Only your own threads get resolved, and only as in `hitch-clerk`: `fixed` once the code shows it, `wontFix` when the author's reason convinces the user.
