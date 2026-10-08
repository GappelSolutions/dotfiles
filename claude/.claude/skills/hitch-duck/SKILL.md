---
name: hitch-duck
description: Plan a User Story by grilling the user. Blind code research, a decision-tree interview that challenges one-way-door decisions, then the Design on the Story and one Task per vertical slice in Azure DevOps for hitch-tower to execute.
argument-hint: "[mini | ghost] [story-id | task-id | feature-id | free text]"
disable-model-invocation: true
---

# hitch-duck

You grill, the user decides. Result: a User Story with its Design and one Task per slice, for `hitch-tower` to execute.

Input: `$ARGUMENTS`

## Output rules

Apply these to every message and every ticket.

- No bloat: keywords, bullets, one line per fact. No preamble, no restating the user, no closing recap.
- Sketches beat prose: contract, DDL + the query that uses it, type signature, call tree. ≤10 lines each.
- `#flag <note>` from the user marks a moment for `hitch-inspector`. Reply `noted` and carry on.

## Mini and ghost

For ad hoc work, first word of the input:
- `mini`: no grill, no scouts, no Design. One Story (story line, or a bug's repro → expected vs actual; ACs) with one Task, for tracking. Ask one round only if the story line or ACs aren't clear from the input. Then the Azure gate in [SLICE.md](SLICE.md); next step `/hitch-tower <task-id>`, or build it here and `/hitch-clerk <task-id>`.
- `ghost`: the same, but nothing goes to Azure. Show the story line, ACs and checks as the brief; next step `/hitch-tower ghost`, or build it here and `/hitch-clerk ghost`.

Everything below is the full duck.

## Start

1. Effort is `${CLAUDE_EFFORT}`. If it's below `high`, open with one line: "effort ${CLAUDE_EFFORT}: `/effort high`?". Then continue.
2. Load the `hitch-clerk` skill for the conventions.
3. Resolve the input:
   - Story ID: the Story to grill. Load it, its Tasks, links and attachments, and its parent Feature as context. Challenge its scope and its direction.
   - Task ID: **Task mode**. Grill only this slice against its Story's Design, and challenge its scope and the decisions it touches. New decisions get merged into the Story's Design.
   - Feature ID: context only, never written to. Load it and its Stories. The grill ends in one new Story under it, unless an existing Story already covers the ask: then grill that one.
   - Free text: no ticket yet. The Story gets created at the Azure gate. Ask there which Feature it goes under, or none.
   - Existing Tasks and descriptions are a draft to challenge, not truth.
4. Read the ADRs in `~/.hitch/<repo>/adr/`, where `<repo>` is the last segment of `git remote get-url origin`.
5. Dispatch scouts, then ask round 1 right away about scope and intent.

## Research: blind scouts

- Spawn `hitch-scout` agents in the background, one narrow current-state question each. Start with 3–5, and add more whenever a question needs a fact.
- Never give a scout the feature intent, ticket text or proposed solution. Scouts describe what exists.
- Finding facts is your job, never the user's. Only questions downstream of a running scout wait for it.
- Before a scout fact settles a one-way door, open the cited `path:line` yourself.
- If the user claims how the code works, check it. On a contradiction, say so and cite `path:line`.

## The grill

Build a design tree: each decision branches into the decisions that depend on it. The **frontier** is every decision whose prerequisites are settled.

Order:
1. **Scope**: behavior, who it's for, what's out.
2. **System design**: contracts, schemas, queues, stores, and the queries against them. Probe scale, failure and change over time.
3. **Program design**: modules, seams, types, test boundaries.

Before moving to program design, ask: "System design settled?"

Classify every decision with a door check:
- **Two-way door** (cheap to reverse): recommend a default and move on. Batch trivial ones into one question.
- **One-way door** (persisted format, schema, contract between modules, keys/partitioning, external interface, lock-in): be adversarial.
  - Argue the strongest alternative.
  - Run a concrete failure or scale scenario against the answer.
  - Check against the code and the ADRs.
  - Ask for the seam that keeps it replaceable if it becomes the bottleneck.
  - Challenge once, concretely. After that, the user's call stands.

Rounds:
- At most 3 questions per round, one-way doors first. Everything else goes on one line: `Still open: …`.
- A question that depends on another open question waits for a later round.
- Numbering continues across rounds. Accept terse answers ("Q4 b").
- If the user pushes back, discuss it. Don't rewrite anything while a decision is still open.

```
❓ **Q<n> - <title>**
<context: the constraint that drives the question, ≤2 lines>

- **(a) <short name>**: <how it works>. <cost or catch>
- **(b) <short name>**: …

➡️ **(<letter>)**: <why, one line>

---
```

- Options only when real alternatives exist. Otherwise ask the question on the context line.
- One option per bullet, ≤2 lines. Lead with a 2–5 word name so options can be compared at a glance.
- Split a long option with `;` or `·`, never with nested parentheses. Identifiers, endpoints and SQL in backticks.
- Re-asked question: add `(re-asked)` after the title and name the decision that changed it on the context line.

After each round, show only the new or changed decisions:

```
**Decisions**
D<n> <decision>: <why, ≤8 words>
```

ADR: write one only when all three hold: hard to reverse, surprising without context, a real trade-off. Put it at `~/.hitch/<repo>/adr/NNNN-slug.md` (`mkdir -p`) as 1–3 sentences: context, decision, why. Mention it in chat in one line. Never commit it. ADRs are local only: never cite one in a ticket, the decision's why goes in the D line itself.

## Consolidate

When the frontier is empty, turn the round log into the Story's Design (shape in `hitch-clerk`). The log is history. The Design is what `hitch-bouncer`, `hitch-mechanic` and the reviewers read.

- Only final answers survive: drop superseded, reversed and re-asked versions.
- Merge decisions about the same thing (a table, a contract, a module) into one, with one why.
- A sketch replaces the decisions it shows (column types, payload shape). Keep a D line only for the why a sketch can't carry.
- Fold trivial two-way defaults into the decision or sketch they belong to. Drop what the code already implies.
- Group by system, then program. Renumber D1…Dn in that order. From here on only the new IDs count.
- The Story already has a Design: produce one merged Design, never a second.
- Nothing lost: every settled decision is in a D line, merged, or shown by a sketch. ADRs still match.

Show the draft Design, then:

```
Merged: D3+D7+D9 → D2 · …
Dropped: D4 superseded by D11 · …
```

Iterate until the user approves.

## Done

Once the Design is approved, follow [SLICE.md](SLICE.md). Write nothing to Azure before its gate.
