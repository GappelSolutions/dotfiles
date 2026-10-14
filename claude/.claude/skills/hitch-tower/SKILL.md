---
name: hitch-tower
description: Execute the Tasks hitch-duck sliced, one PR each. Per Task a readiness gate, implementation in its own worktree, dev validation and an annotated draft PR for your feedback, reviewed per batch at a depth sized to its risk; merges once someone else approves with no comment unaddressed, then starts the next batch until its Stories are done. Start it only when the user asks for it.
argument-hint: "<story-id... | task-id... | ghost>"
---

# hitch-tower

You run the crew and talk to the user. You don't write code: each Task gets its own worktree and agents.

Input: `$ARGUMENTS`

## Output rules

- No bloat: keywords, bullets, one line per fact. Status lines, not narration.
- The user reads code in the PR. In chat: what changed and why, never the code itself.
- PR description and annotations are read by colleagues: raw info a reviewer needs, readable like the tickets.
- `#flag <note>` from the user marks a moment for `hitch-inspector`. Reply `noted` and carry on.

## Crew

| agent | does | model · effort |
|---|---|---|
| `hitch-bouncer` | loads a Task and its Story from Azure: brief + Ready verdict | haiku · medium |
| `hitch-mechanic` | builds one Task in its worktree, or one fix round on it; returns a hand-off with annotations | sonnet · high (trial) |
| `hitch-gofer` | tool-call chains: dev deploy + checks, screenshot, slow checks (full suite, e2e), after-merge pipelines + check | haiku · medium |
| `hitch-skeptic` | review of a batch: one, or two independently at tier `full` | opus · high · B at `full`: sonnet (trial) |
| `hitch-referee` | tier `full`: verifies both reviews, the final fix list per Task | opus · high |
| `general-purpose` | the `hitch-janitor` skill once the Story is done | sonnet · medium |

Spawn them in the background with absolute paths. Keep only their reports in your context. `hitch-pr` means `~/.claude/skills/hitch-tower/hitch-pr`.

Mechanics are short-lived: a subagent's cache expires after 5 idle minutes, and waking it re-writes its whole context.
- One run each, never SendMessage one: every fix round, dev failure or conflict gets a fresh mechanic with the worktree, the brief, the last hand-off and the request.
- Slow work (dev deploy, full suite, e2e, pipelines) runs in a gofer after the hand-off, never in the mechanic.
- At most 2 mechanics running per tower session. The next one starts when one hands off: Tasks queue rather than burst the 5h limit.

## Start

1. Load the `hitch-clerk` skill.
2. Resolve the input into Tasks:
   - Story IDs: their child Tasks that aren't `Closed` or `Removed`. Several Stories share one Loop.
   - Task IDs: those.
   - `ghost`: the brief from this session's `/hitch-duck ghost`, one Task with no ID. No bouncer, no Azure states, links or Plan. Branch: the naming rule without the ID.
3. Rebuild the state from Azure and git, per Task: its PR and PR status, whether its worktree exists, which dev namespace it leases (step 5); its `refs/hitch/<task-id>/{base,reviewed}` (steps 4, 10); its after-merge record `~/.local/state/hitch/after-merge/<task-id>` (step 11): show its `RESULT` line. Never keep a state file. A later session resumes the same way.
4. Show `| Task | state | PR | blocked by |`, then enter the loop where each Task stands.

## Loop

The frontier is every Task whose Predecessors are all `Closed`. A batch is the frontier Tasks built together: at most 3, their mechanics 2 at a time; the rest form the next batch. A Task still in its duck (step 1) joins a later batch.

1. **Gate**: `hitch-bouncer` per Task.
   - READY: its brief is your context for that Task.
   - GAPS: show them in one block, then read `~/.claude/skills/hitch-duck/SKILL.md` and follow it, including its Azure gate: on the Story if the gap is the Story's (story line, ACs, Design), else in Task mode. Bounce again. Other Tasks keep going.
2. **Worktree**: set the states for a started Task, as in `hitch-clerk` (Task, Story).
   ```bash
   git fetch origin
   git worktree add ~/.local/state/hitch/wt/<repo>/<task-id> -b <branch> origin/<default>
   ```
   `<default>`: `git symbolic-ref --short refs/remotes/origin/HEAD`. `<branch>`: the naming rule in the repo's CLAUDE.md/AGENTS.md or its pre-PR skill, with the Task's ID and title, e.g. `<initials>_T<task-id>_<Title_Words>`, with the placeholders filled in as in your own branches (`git for-each-ref refs/remotes --format='%(authoremail) %(refname:short)'`). No rule: the convention in `git branch -r`.
3. **Build**: `hitch-mechanic` with the worktree and the brief. It returns a hand-off.
   - **Open** items: run the duck in Task mode on them, then a fresh `hitch-mechanic` with the worktree, the updated brief and the hand-off. Review waits for it.
   - **Checks** marked `→ tower`: a `hitch-gofer` runs them in the worktree. A failure: a fresh mechanic with its report.
4. **Review**, once per batch, after every mechanic in it has handed off. Reviews stay in chat, never on Azure. The crew below is the whole review: no other review agents.
   - **Tier**, from `git diff --stat <base>...HEAD` and the touched paths, the batch's highest. State it in one line with the reason.
     - `none`: nothing to judge. Generated or lock files only, a revert, a version or config bump.
     - `one`, the default: one `hitch-skeptic`. Its findings are the Fix list, its questions the Open items.
     - `full`: a migration or schema change, auth or secrets, a contract between services, concurrency or failure handling (queues, retries, transactions), > ~400 changed lines outside tests and generated files, or the user asks. Two `hitch-skeptic` runs in parallel with the same input, neither sees the other, B with the model override `sonnet` (trial, measured by `hitch-inspector`). Each writes to `/tmp/hitch-<story-id>/review-<batch>-<A|B>.md` and returns only the path. Then `hitch-referee` with the same input plus both files.
   - Input per Task: the worktree, the base, the brief, the hand-off.
   - After it: `git update-ref refs/hitch/<task-id>/base <base>` and `refs/hitch/<task-id>/reviewed HEAD`. Local only, never pushed.
   - The **Fix** list per Task goes to a fresh mechanic for that Task. The **Open** items go to the user in step 7.
   - **Reruns**: a later change (fixes, feedback, a rebase) is never reviewed in full again. Only the new part: `refs/hitch/<task-id>/reviewed..HEAD`. After a rebase, only what `git range-diff <old-base>..<reviewed> <new-base>..HEAD` marks changed, plus conflict resolutions (`git show --remerge-diff <merge>`). Tier `none`, unless the new part alone hits a `full` trigger (then `full`) or exceeds ~100 changed lines (then `one`). Applied Fix lists: `none`, the checks cover them. Move both refs.
5. **Dev**: each Task gets its own dev namespace, so Tasks deploy in parallel.
   - Pool: your dev namespace `<ns>` on the dev cluster, plus its numbered siblings (`<ns>2`, `<ns>3`, …), each with its own DB, broker vhost and NodePorts. No siblings: `<ns>` alone, one Task at a time.
   - Lease: a namespace without a `hitch-lease` ConfigMap is free, and `<ns>` goes first. Take it with `oc create configmap hitch-lease -n <ns> --from-literal=task=<task-id>`. The lease lives in the cluster, so a later session finds it (Start, step 3). None free: the Task waits.
   - Keep it until the Task is closed, so feedback redeploys land in the same place. Then `oc delete configmap hitch-lease -n <ns>`.
   - Before every deploy: `data.task` still `<task-id>` → `oc annotate configmap hitch-lease -n <ns> hitch/renewed=$(date -u +%FT%TZ) --overwrite`; gone or another Task's → lease a free one again. `hitch-reaper` (systemd timer, every 10 min) releases a lease whose Task is closed, whose PRs are all closed, or that has no PR and wasn't renewed for 3 h.
   - A `hitch-gofer` with the worktree, `<ns>`, the Task's dev checks, and whether it's a UI change: it deploys, checks and screenshots. A failure in the code: a fresh mechanic with its report, then a new gofer.
6. **Draft PR**: `git push -u origin <branch>`, create the draft as in `hitch-clerk`, then `hitch-pr annotate <pr> <file>` with the last hand-off's annotations. Add the gofer's deployed URL to the description, and for a UI change upload its screenshot, as in `hitch-clerk`. Again after a push with a new screenshot.
7. **Report** per Task:
   ```
   **T<n> #<task> <title>** → <pr-url>
   - task: <its scope line>
   - checks: auto ✅ · dev ✅ <what was observed>
   - review: <n> fixed · <n> dropped · open: <question>
   ```
8. **Feedback**: the user goes over the draft, in chat or as Azure comments you didn't post.
   - Questions: answer from the worktree. Spawn `hitch-scout` for wide ones.
   - Change requests: a fresh `hitch-mechanic` with the worktree, the brief, the last hand-off and the request, then checks, then step 4's Reruns, then push. If a change contradicts a decision, run the duck in Task mode first.
   - After every push, bring the description and the annotations up to date with the code, as in `hitch-clerk`. Colleagues must always see the full picture, and nothing may contradict.
   - Repeat until the user says `publish` or publishes it on Azure.
   - The Plan (`hitch-clerk`): redraw it after every Task state change, on the Story and in the descriptions of the Story's open PRs.
9. **Publish**: `az repos pr update --id <pr> --draft false`, then move the Task to the taskboard's review column, as in `hitch-clerk`.
10. **Ahead**, alongside step 11: while a batch waits on review, run the next batch early instead of idling. It may be thrown away if review changes the concept: that's accepted.
    - Steps 1–4 as for any batch: its own worktree and a fresh mechanic per Task. Base: its Predecessors' branches instead of `origin/<default>` (several: merged into the new branch first). No dev deploy, no PR, no push. Task states stay `New`.
    - The next ahead batch starts only once this one's fixes are in.
    - A Predecessor gets a push: a `hitch-gofer` runs `git rebase --onto <new base> refs/hitch/<task-id>/base` and the checks; a conflict: a fresh mechanic resolves it. Then step 4's Reruns, and if the Predecessor's push itself hit a `full` trigger, tier `one` at least, with that push's diff as context. Feedback that changes the Design: name the ahead Tasks it hits, the user says rebuild or drop.
    - Predecessors close: the same rebase onto `origin/<default>`, then step 5 on.
11. **Wait**: run `hitch-pr wait <pr-id>...` in the background on every open PR. It exits on any status, draft, vote or comment change. Then, per changed PR:
    - New comments from others: one line each, plus a proposed reply or fix. Post and push nothing without the user's OK. Resolve threads only as in `hitch-clerk`: `fixed` once the fix is pushed, `wontFix` with the reason. A reply alone leaves the thread open.
    - Then `hitch-pr gate <pr>`:
      - READY (someone else approved with 10, no negative vote, no unaddressed thread, no conflicts): complete the PR as in `hitch-clerk`. The user's approval of the workflow covers this. No need to ask.
      - BLOCKED: show the blockers unless they're only "no approval yet", and keep waiting.
    - `completed`: claim it first, `mkdir -p ~/.local/state/hitch/after-merge && echo "tower $(date -u +%FT%TZ) PR <pr>" > ~/.local/state/hitch/after-merge/<task-id>`. A record already there: another session or `hitch-reaper` ran it, so show its `RESULT` and don't run it again. Then **After merge** as in `hitch-clerk`, and append `RESULT: pass` or `RESULT: fail <why>` to the record. Pass: close the Task, release the dev namespace, `git worktree remove <path>`, `git branch -d <branch>` (never force), `git update-ref -d` both `refs/hitch/<task-id>/*`. Recompute the frontier and go to step 1.
    - Restart the wait with the PRs still open.
    - Every user message, whatever it's about, starts with `hitch-pr status <pr-id>...` on the Loop's open PRs: the user often merges on Azure themselves. A `completed` one goes through the step above before the reply.
12. **Done**, per Story: once its Tasks are all `Closed`, close it as in `hitch-clerk`, run `hitch-janitor` in a `general-purpose` agent (`Follow ~/.claude/skills/hitch-janitor/SKILL.md for Story <id> in <repo path>.`), and report its findings. The Loop goes on with the other Stories.
