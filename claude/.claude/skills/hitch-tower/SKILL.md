---
name: hitch-tower
description: Execute the Stories hitch-duck sliced. Per Story a readiness gate, implementation in its own worktree, three reviews, dev validation and an annotated draft PR for your feedback; merges once someone else approves with no comment unaddressed, then starts the next batch until the Feature is done.
argument-hint: "<feature-id | story-id...>"
disable-model-invocation: true
---

# hitch-tower

You run the crew and talk to the user. You don't write code: each Story gets its own worktree and agents.

Input: `$ARGUMENTS`

## Output rules

- No bloat: keywords, bullets, one line per fact. Status lines, not narration.
- The user reads code in the PR. In chat: what changed and why, never the code itself.
- PR description and annotations are read by colleagues: raw info a reviewer needs, readable like the tickets.
- `#flag <note>` from the user marks a moment for `hitch-inspector`. Reply `noted` and carry on.

## Crew

| agent | does | effort |
|---|---|---|
| `hitch-bouncer` | loads a Story from Azure: brief + Ready verdict | low |
| `hitch-mechanic` | builds one Story in its worktree: fixes, dev deploy, annotations | high |
| `hitch-skeptic` | full review; two run independently | high |
| `hitch-referee` | third review, with both as input: the final fix list | high |
| `hitch-janitor` | cleanup once the Feature is done | medium |

Spawn them in the background with absolute paths. Keep only their reports in your context. `hitch-pr` means `~/.claude/skills/hitch-tower/hitch-pr`.

## Start

1. Load the `hitch-clerk` skill.
2. Resolve the input into Stories:
   - Feature ID: its child Stories that aren't `Closed` or `Removed`.
   - Story IDs: those.
3. Rebuild the state from Azure and git, per Story: its PR and PR status, whether its worktree exists, which dev namespace it leases (step 5). Never keep a state file. A later session resumes the same way.
4. Show `| Story | state | PR | blocked by |`, then enter the loop where each Story stands.

## Loop

The frontier is every Story whose Predecessors are all `Closed`. Run them in parallel: at most 3 mechanics at once, the rest queue.

1. **Gate**: `hitch-bouncer` per Story.
   - READY: its brief is your context for that Story.
   - GAPS: show them in one block, then grill the Story: read `~/.claude/skills/hitch-duck/SKILL.md` and follow it in Story mode, including its Azure gate. Bounce again. Other Stories keep going.
2. **Worktree**: set the states for a started Story, as in `hitch-clerk` (Story, Tasks, Feature).
   ```bash
   git fetch origin
   git worktree add ~/.local/state/hitch/wt/<repo>/<story-id> -b <branch> origin/<default>
   ```
   `<default>`: `git symbolic-ref --short refs/remotes/origin/HEAD`. `<branch>`: the naming rule in the repo's CLAUDE.md/AGENTS.md or its pre-PR skill, e.g. `<initials>_U<story-id>_<Title_Words>`, with the placeholders filled in as in your own branches (`git for-each-ref refs/remotes --format='%(authoremail) %(refname:short)'`). No rule: the convention in `git branch -r`.
3. **Build**: `hitch-mechanic` with the worktree and the brief. It returns a hand-off.
4. **Review**, always, for every Story. Reviews stay in chat, never on Azure.
   - Two `hitch-skeptic` runs in parallel with the same input: the worktree, `origin/<default>` as base, the brief and the hand-off. Duplicate on purpose: AI reviews aren't consistent. Neither sees the other.
   - Then `hitch-referee` with the same input plus both reviews, as A and B.
   - Its **Fix** list goes to the Story's mechanic (SendMessage, context intact). Its **Open** items go to the user in step 7.
5. **Dev**: each Story gets its own dev namespace, so Stories deploy in parallel.
   - Pool: your dev namespace `<ns>` on the dev cluster, plus its numbered siblings (`<ns>2`, `<ns>3`, …), each with its own DB, broker vhost and NodePorts. No siblings: `<ns>` alone, one Story at a time.
   - Lease: a namespace without a `hitch-lease` ConfigMap is free, and `<ns>` goes first. Take it with `oc create configmap hitch-lease -n <ns> --from-literal=story=<story-id>`. The lease lives in the cluster, so a later session finds it (Start, step 3). None free: the Story waits.
   - Keep it until the Story is closed, so feedback redeploys land in the same place. Then `oc delete configmap hitch-lease -n <ns>`.
   - Tell the mechanic: "deploy to `<ns>`, run the dev checks, then the annotations".
6. **Draft PR**: `git push -u origin <branch>`, create the draft as in `hitch-clerk`, then `hitch-pr annotate <pr> <file>` with the mechanic's annotations.
7. **Report** per Story:
   ```
   **S<n> #<story> <title>** → <pr-url>
   - story: <the "I want" part>
   - checks: auto ✅ · dev ✅ <what was observed>
   - review: <n> fixed · <n> dropped · open: <question>
   ```
8. **Feedback**: the user goes over the draft, in chat or as Azure comments you didn't post.
   - Questions: answer from the worktree. Spawn `hitch-scout` for wide ones.
   - Change requests: to the mechanic, then checks, then push. If a change contradicts a decision, run the Story-mode duck first.
   - After every push, bring the description and the annotations up to date with the code, as in `hitch-clerk`. Colleagues must always see the full picture, and nothing may contradict.
   - Repeat until the user says `publish` or publishes it on Azure.
9. **Publish**: `az repos pr update --id <pr> --draft false`, then move the Story's Tasks to the taskboard's review column, as in `hitch-clerk`.
10. **Wait**: run `hitch-pr wait <pr-id>...` in the background on every open PR. It exits on any status, draft, vote or comment change. Then, per changed PR:
    - New comments from others: one line each, plus a proposed reply or fix. Post and push nothing without the user's OK. Resolve threads only as in `hitch-clerk`: `fixed` once the fix is pushed, `wontFix` with the reason. A reply alone leaves the thread open.
    - Then `hitch-pr gate <pr>`:
      - READY (someone else approved with 10, no negative vote, no unaddressed thread, no conflicts): complete the PR as in `hitch-clerk`. The user's approval of the workflow covers this. No need to ask.
      - BLOCKED: show the blockers unless they're only "no approval yet", and keep waiting.
    - `completed`: **after-merge check**, a smoke test of what was merged, nothing more.
      1. Wait for the pipeline run of the merge commit (`lastMergeCommit` in `az repos pr show`) on `<default>` to deploy to the shared dev environment: `az pipelines runs list --branch <default> --top 10`, then `az pipelines runs show --id <run>`.
      2. Tell the mechanic: "run the dev checks against shared dev". It sends the input, reads the result and cleans up. It deploys, configures and fixes nothing.
      3. Pass: close the Story and its Tasks as in `hitch-clerk`, release the dev namespace, `git worktree remove <path>`, `git branch -d <branch>` (never force). Recompute the frontier and go to step 1.
      4. Fail, or the check needed setup: that's something the PR forgot. Report it, and the user decides: a follow-up Story or a revert. The Story stays open.
    - Restart the wait with the PRs still open.
    - A user message cuts the wait short: check the PRs right away.
11. **Done**: once every Story is `Closed`, run `hitch-janitor` with the Feature ID and the repo path, and report its findings. Suggest `Resolved` for the Feature, and set it only on the user's OK.
