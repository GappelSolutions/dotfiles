---
name: hitch-tower
description: Execute the Tasks hitch-duck sliced, one PR each. Per Task a readiness gate, implementation in its own worktree, dev validation and an annotated draft PR for your feedback, with three reviews per batch; merges once someone else approves with no comment unaddressed, then starts the next batch until the Story is done.
argument-hint: "<story-id | task-id... | ghost>"
disable-model-invocation: true
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
| `hitch-mechanic` | builds one Task in its worktree: fixes, dev deploy through a gofer, annotations | opus · high |
| `hitch-gofer` | tool-call chains: dev deploy + checks, screenshot (for the mechanic), after-merge pipelines + check | haiku · medium |
| `hitch-skeptic` | full review of a batch; two run independently | A opus · B sonnet (trial) · high |
| `hitch-referee` | third review of a batch, with both as input: the final fix list per Task | opus · high |
| `hitch-janitor` | cleanup once the Story is done | sonnet · medium |

Spawn them in the background with absolute paths. Keep only their reports in your context. `hitch-pr` means `~/.claude/skills/hitch-tower/hitch-pr`.

## Start

1. Load the `hitch-clerk` skill.
2. Resolve the input into Tasks:
   - Story ID: its child Tasks that aren't `Closed` or `Removed`.
   - Task IDs: those.
   - `ghost`: the brief from this session's `/hitch-duck ghost`, one Task with no ID. No bouncer, no Azure states, links or Plan. Branch: the naming rule without the ID.
3. Rebuild the state from Azure and git, per Task: its PR and PR status, whether its worktree exists, which dev namespace it leases (step 5); per Story, whether a `-full` worktree exists (step 10). Never keep a state file. A later session resumes the same way.
4. Show `| Task | state | PR | blocked by |`, then enter the loop where each Task stands.

## Loop

The frontier is every Task whose Predecessors are all `Closed`. A batch is the frontier Tasks built together: at most 3 (the mechanic cap), the rest form the next batch. A Task still in its duck (step 1) joins a later batch.

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
4. **Review**, always, once per batch, after every mechanic in it has handed off. Reviews stay in chat, never on Azure.
   - Two `hitch-skeptic` runs in parallel with the same input, per Task of the batch: the worktree, `origin/<default>` as base, the brief and the hand-off. Duplicate on purpose: AI reviews aren't consistent. Neither sees the other. Spawn B with the model override `sonnet` (trial, measured by `hitch-inspector`).
   - Then `hitch-referee` with the same input plus both reviews, as A and B.
   - Its **Fix** list per Task goes to that Task's mechanic (SendMessage, context intact). Its **Open** items go to the user in step 7.
5. **Dev**: each Task gets its own dev namespace, so Tasks deploy in parallel.
   - Pool: your dev namespace `<ns>` on the dev cluster, plus its numbered siblings (`<ns>2`, `<ns>3`, …), each with its own DB, broker vhost and NodePorts. No siblings: `<ns>` alone, one Task at a time.
   - Lease: a namespace without a `hitch-lease` ConfigMap is free, and `<ns>` goes first. Take it with `oc create configmap hitch-lease -n <ns> --from-literal=task=<task-id>`. The lease lives in the cluster, so a later session finds it (Start, step 3). None free: the Task waits.
   - Keep it until the Task is closed, so feedback redeploys land in the same place. Then `oc delete configmap hitch-lease -n <ns>`.
   - The mechanic, with `<ns>`, the Task's dev checks, and whether it's a UI change: it deploys, checks and screenshots through a gofer and fixes what fails. Then it writes the annotations.
6. **Draft PR**: `git push -u origin <branch>`, create the draft as in `hitch-clerk`, then `hitch-pr annotate <pr> <file>` with the mechanic's annotations. Add the mechanic's deployed URL to the description, and for a UI change upload its screenshot, as in `hitch-clerk`. Again after a push with a new screenshot.
7. **Report** per Task:
   ```
   **T<n> #<task> <title>** → <pr-url>
   - task: <its scope line>
   - checks: auto ✅ · dev ✅ <what was observed>
   - review: <n> fixed · <n> dropped · open: <question>
   ```
8. **Feedback**: the user goes over the draft, in chat or as Azure comments you didn't post.
   - Questions: answer from the worktree. Spawn `hitch-scout` for wide ones.
   - Change requests: to the mechanic, then checks, then push. If a change contradicts a decision, run the duck in Task mode first.
   - After every push, bring the description and the annotations up to date with the code, as in `hitch-clerk`. Colleagues must always see the full picture, and nothing may contradict.
   - Repeat until the user says `publish` or publishes it on Azure.
   - The Plan (`hitch-clerk`): redraw it after every Task state change, on the Story and in the descriptions of the Story's open PRs.
9. **Publish**: `az repos pr update --id <pr> --draft false`, then move the Task to the taskboard's review column, as in `hitch-clerk`.
10. **Ahead**, alongside step 11: while a batch waits for review, build the next batches on a `-full` branch instead of idling. It may be thrown away if review changes the concept: that's accepted.
    - Branch: the Task naming rule with the Story ID and a `_full` suffix. Worktree `~/.local/state/hitch/wt/<repo>/<story-id>-full`, from `origin/<default>` with the waiting batch's branches merged in.
    - One mechanic at a time, Task by Task in batch order, each Task its own commits (message prefix as its Task branch would use). Automated checks only: no review, no dev deploy, no PR, no push. Task states stay `New`.
    - Feedback pushed on a waiting PR: the mechanic rebases `-full` onto it. Feedback that changes the Design: name the built-ahead Tasks it hits, the user says rebuild or drop.
    - A Task's Predecessors close: step 2 cuts its branch from `origin/<default>` and the mechanic cherry-picks its commits from `-full` (resolves conflicts, re-runs the checks), then step 4 on. Done when every Task is cut: delete `-full` and its worktree.
11. **Wait**: run `hitch-pr wait <pr-id>...` in the background on every open PR. It exits on any status, draft, vote or comment change. Then, per changed PR:
    - New comments from others: one line each, plus a proposed reply or fix. Post and push nothing without the user's OK. Resolve threads only as in `hitch-clerk`: `fixed` once the fix is pushed, `wontFix` with the reason. A reply alone leaves the thread open.
    - Then `hitch-pr gate <pr>`:
      - READY (someone else approved with 10, no negative vote, no unaddressed thread, no conflicts): complete the PR as in `hitch-clerk`. The user's approval of the workflow covers this. No need to ask.
      - BLOCKED: show the blockers unless they're only "no approval yet", and keep waiting.
    - `completed`: **After merge** as in `hitch-clerk`. Pass: close the Task, release the dev namespace, `git worktree remove <path>`, `git branch -d <branch>` (never force). Recompute the frontier and go to step 1.
    - Restart the wait with the PRs still open.
    - A user message cuts the wait short: check the PRs right away.
12. **Done**: once every Task is `Closed`, close the Story as in `hitch-clerk`, run `hitch-janitor` with the Story ID and the repo path, and report its findings.
