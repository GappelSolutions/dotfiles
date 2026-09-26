# Code rules

Used by `hitch-mechanic` (writes), `hitch-skeptic` and `hitch-referee` (check). The repo's own conventions win: its CLAUDE.md/AGENTS.md and the code next to the change.

## Comments

Default: no comment. Code says what; a comment only says the why the code can't.

Keep:
- a non-obvious why: a constraint, an invariant, a workaround (with its issue link), a choice a reader would otherwise "fix"
- public API docs where the repo documents its API, and only what the signature can't say: units, ranges, side effects, ownership

Delete:
- restating the code: `// increment counter`, `// loop over devices`
- narrating the change or its history: "added", "new", "now uses", "fixed", "changed from X", "as requested", Story IDs
- banners and dividers: `// ---- helpers ----`
- commented-out code
- docstrings that repeat the name and parameters
- TODO/FIXME without a ticket ID
- filler: "Note that", "basically", "simply", "This function is responsible for"
- a comment that explains a bad name: rename instead

Scope: lines the diff adds or touches. Old slop elsewhere stays out of the PR.

## Code

- Match the surrounding code: naming, structure, error handling, logging, test style.
- The smallest change that delivers the Story. No speculative abstraction, options or extension points.
- No premature optimization, but keep bottlenecks replaceable behind the seams the Design decided.
- No dead code, unused parameters, debug leftovers, or defensive checks for states the types or callers rule out.
- Errors: handle them where you can act, otherwise propagate them with context. Never swallow one.
- Logs carry information (IDs, counts, durations), never "entering X".
- Tests: behavior at the boundaries the Design names. Each one fails if the code is wrong. Don't test the framework or the mocks.
- Stay in the Story. Anything else goes in the hand-off, not the diff.

## Text

Commit messages and PR descriptions: what and why, no bloat, never how you got there.
