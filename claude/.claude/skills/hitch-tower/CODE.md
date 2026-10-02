# Code rules

Used by `hitch-mechanic` (writes), `hitch-skeptic` and `hitch-referee` (check). The repo's own conventions win: its CLAUDE.md/AGENTS.md and the code next to the change.

## Comments

Default: no comment. Code says what; a comment only says the why the code can't.

The test: would a reviewer misread the code, or "fix" it wrongly, without this comment? If not, delete it. "It is informative" or "it documents the behaviour" is not a reason to keep one.

Keep, and only this:
- a non-obvious why: a constraint, an invariant, an ordering, transaction or DST reason, a workaround (with its issue link), a deliberate trade-off a reader would otherwise "fix"
- docs on a public API the repo already documents that way, and only what the signature can't say: units, ranges, side effects, ownership. Not on internal types.

Never write a `<summary>`/docstring on:
- records, DTOs, request/response types, options and config classes, entities, enums and their members
- interfaces and their methods, repository and client methods, endpoints and handlers
- private and internal methods whose name and signature say it
- tests and test helpers

Delete:
- restating the code, the type, the method name or its parameters: `// increment counter`, "Gets the...", "Returns the...", "Represents a..."
- narrating the change or its history: "added", "new", "now uses", "fixed", "changed from X", "as requested", work item IDs, spec section numbers, ADR refs
- banners and dividers: `// ---- helpers ----`
- commented-out code
- TODO/FIXME without a ticket ID
- filler: "Note that", "basically", "simply", "This function is responsible for"
- a comment that explains a bad name: rename instead

One sentence is the norm, as a `//` line above the code it explains. A multi-line `<summary>` is the exception and must justify itself. If a new class or file needs several comments, the code is not clear enough: fix the code.

Budget: a PR with more than ~1 comment per 200 changed lines of non-test code has too many. Count them before handing off or reviewing, and cut to the ones that pass the test.

Scope: lines the diff adds or touches. Old slop elsewhere stays out of the PR.

## Code

- Match the surrounding code: naming, structure, error handling, logging, test style.
- The smallest change that delivers the Task. No speculative abstraction, options or extension points.
- No premature optimization, but keep bottlenecks replaceable behind the seams the Design decided.
- No dead code, unused parameters, debug leftovers, or defensive checks for states the types or callers rule out.
- Errors: handle them where you can act, otherwise propagate them with context. Never swallow one.
- Logs carry information (IDs, counts, durations), never "entering X".
- Tests: behavior at the boundaries the Design names. Each one fails if the code is wrong. Don't test the framework or the mocks.
- Stay in the Task. Anything else goes in the hand-off, not the diff.

## Text

Commit messages and PR descriptions: what and why, no bloat, never how you got there.
