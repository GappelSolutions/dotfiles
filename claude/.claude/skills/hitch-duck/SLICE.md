# Slice

Turn the approved Design into Tasks under the Story: one Task per slice, one PR each. The ticket shapes are in `hitch-clerk`.

## Rules

- **Task = one PR = a vertical slice**: a narrow but complete path through every layer it needs. It ends in something that can be run, queried or observed. Never one layer on its own.
- Size: reviewable in one sitting (≤ ~40 annotations, see `hitch-clerk`), and doable in one fresh `hitch-mechanic` context.
- Prefactor first ("make the change easy, then make the easy change"). Prefactor Tasks block the rest.
- A wide mechanical change (rename, retype across the codebase) is split as expand → migrate batches → contract, each part its own Task.
- Blockers are real gates only. Maximize what can run in parallel.
- Title: the slice's outcome, verb first, ≤60 chars. Description: 1–2 lines of scope. No steps and no decisions: the Design stays on the Story.
- Checks for each Task:
  - automated: the exact commands
  - dev: the input to send, what to read back (a message on queue X, rows in table Y, an endpoint's response), and what to clean up. It must run as is against any deployed environment: no deploying, no config.
- One Story by default. A new Story only if the PO could ship or drop it on its own (another role or benefit), never for a prefactor, migration or cleanup. More than ~5 Tasks: ask whether to split by value. A new Story gets its own story line, ACs and Design: the decisions it needs, in full, no refs.
- Task mode: re-slice the one Task. If it's too big, propose sibling Tasks under the same Story.

## Present

```
| # | Task | delivers | blocked by |
Batches: B1 T1,T2 · B2 T3 · …
```

More than one Story: one table each, under its story line.

Ask whether the granularity is right, whether the edges are right, and whether anything should be merged or split. Iterate until the user approves.

## Azure gate

1. Show exactly what will be written: new items, changed items, and items to close.
2. Wait for an explicit "go".
3. Write the items as described in `hitch-clerk`.
4. Write the Story's `## Plan` (`hitch-clerk`). Reply with one table (`# | ID | title | blocked by`) and the next step: `/hitch-tower <story-id>`.
