# Slice

Turn the settled decisions into Stories (one per PR) and Tasks (the minimal steps inside it). The ticket shapes are in `hitch-clerk`.

## Rules

- **Story = one PR = a vertical slice**: a narrow but complete path through every layer it needs. It ends in something that can be run, queried or observed. Never one layer on its own.
- Size: reviewable in one sitting, and doable in one fresh `hitch-tower` context.
- Prefactor first ("make the change easy, then make the easy change"). Prefactor Stories block the rest.
- A wide mechanical change (rename, retype across the codebase) is split as expand → migrate batches → contract, each part its own Story.
- Blockers are real gates only. Maximize what can run in parallel.
- Tasks: the ordered minimal steps inside a Story, each a compilable, testable increment. A title is enough; add one line only if the step isn't obvious.
- Checks for each Story:
  - automated: the exact commands
  - dev: the input to send, what to read back (a message on queue X, rows in table Y, an endpoint's response), and what to clean up. It must run as is against any deployed environment: no deploying, no config.
- Stories reference decisions by ID and never copy them.
- Story mode: slice the one Story into Tasks. If it's too big, propose sibling Stories under the same parent.

## Present

```
| # | Story | delivers | blocked by | tasks |
Batches: B1 S1,S2 · B2 S3 · …
```

Ask whether the granularity is right, whether the edges are right, and whether anything should be merged or split. Iterate until the user approves.

## Azure gate

1. Show exactly what will be written: new items, changed items, and items to close.
2. Wait for an explicit "go".
3. Write the items as described in `hitch-clerk`.
4. Reply with one table (`# | ID | title | blocked by`) and the next step: `/hitch-tower <feature-id>` (Story mode: `/hitch-tower <story-id>`).
