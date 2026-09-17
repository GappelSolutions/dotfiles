---
name: pre-pr
description: Pre-PR conventions checklist for this repo — branch/commit naming, code conventions, and the author checklist before requesting review. Use before opening a PR, un-drafting one, or when asked whether something is "PR-ready".
---

Work through this in order before opening or un-drafting a PR. It's a checklist, not
a licence to silently "fix" things by rewriting unrelated code.

## 1. Review pass first

Review first, standards second — they intertwine, but review comes first so its
findings inform the rest of the pass instead of being a final checkbox:

1. **Run both `/code-review` and `/security-review` on the diff before anything
   else** — every PR, no exceptions, not just auth-adjacent ones. Treat them as a
   senior-engineer pass, not an AI formality, and surface the findings to the user as
   the first feedback on the PR. Nothing in CI can enforce this step, so it only
   happens if you do it.
2. **Walk the rest of this checklist**, using the review findings as input — e.g. a
   review hit on a magic string or dead code feeds directly into the conventions
   check below rather than being tracked separately.
3. Only once the review findings are resolved (or consciously deferred) and the rest
   of this checklist is clean does the PR come out of draft.

## 2. Code conventions

Applies to every change, regardless of who or what wrote it. Check the
[angular skill](../angular/SKILL.md) for the full conventions — in particular that the
change uses current Angular 22 idioms (signals, not legacy `@Input()`/`NgModule`), is
consistent with the surrounding code, and weakens no existing security behaviour.

- No inline `template:` strings — every component uses `templateUrl` to its own
  `.html` file (see [components](../angular/references/components.md)).
- Test `it()` titles state a fact, present tense, no `should`, no placeholder
  (`'disables the submit button while saving'`, not `'should work'`/`'test 1'`)
  — lint-enforced (`vitest/valid-title`), but check anyway
  (see [testing](../angular/references/testing.md)).
- No magic strings — extract to a `const`/central `enum`.
- **Compact the comments.** Agents over-comment by default. Delete anything that
  restates what the code already says, and delete commented-out code outright (git
  has the history). Keep a comment only when it carries a WHY the code cannot: a
  hidden constraint, a non-obvious invariant, or a workaround for a specific bug.
  The comments left should be compacted as far as possible.
- Anything under `bun gen`'s output or
  `i18n-keys.generated.ts` stays out of Prettier's scope (`.prettierignore`) —
  hand-formatted diffs on generated code are pure churn.
- Always use `bun gen` for api integration. There should be no handwritten HTTP
  clients. If there's an API, there should be an OpenAPI spec making it
  regenearatable.

## 3. Requirements before requesting review

- Green locally. Have devenv? `devenv tasks run cicd:dry` replays the whole CI
  pipeline (secrets → ready → lint → test → build → e2e). No devenv — which is the norm
  on Windows — run `bun ready`, `bun lint` and `bun nx:test` directly instead; add
  `bun e2e` if the change touches anything the e2e suite drives.
- No secrets in the tree. `cicd:dry` fails fast on this via `gdm-ui:secrets`, and CI
  repeats it in the Lint stage. Without devenv, run `gitleaks dir . --redact` with a
  gitleaks binary on `$PATH`, or lean on the CI step. A hit is never "quiet the
  scanner" — rotate the credential first, then purge it from the tree.
- Coverage is gated, not eyeballed: `vitest-base.config.ts` fails any project below
  80% on lines/branches/functions/statements, scoped to that project's own
  `src/**/*.ts`. A red project fails its test target — close the gap with tests
  rather than lowering the threshold.
- Dependency vulnerabilities are gated in CI's Build stage: `osv-scanner` reads
  `bun.lock` directly and fails the build on any known advisory. Reproduce it locally
  with `devenv shell -- osv-scanner scan source --lockfile=bun.lock` before blaming CI.
  Fix by bumping the offending package; if it's an unfixable transitive dev-only
  dependency, an `osv-scanner.toml` ignore with an expiry date is the escape hatch —
  and that's a deliberate, reviewed decision, not a reflex.
- Code in the change is actually used and scoped to the task — no drive-by extras.
- PR stays in draft until the above and the review pass from step 1 are done.
- Don't mix a functionality change with a style/refactor pass in the same PR.

## 4. Git conventions

Nothing needs to be committed while working through the steps above — that's why this
comes last.

- Branch: `<3-letter initials>_<Task/US#>_<Header>` (e.g. `CGA_T6206_Angular_Setup`).
- Commits: descriptive, reference the work item (`#1234`).
- Batch follow-up commits (review feedback, fixups) into one push rather than pushing
  on every small change.
- Never mention the AI Model/Company in the message. It's useless noise

## 5. Next steps

1. If the work isn't already on a correctly-named branch with the commits it needs,
   prepare that now — rename the branch to match the convention above, then stage and
   commit per §4. This repo is plain git (no `.jj`), so use git commands.
2. **Ask the user** whether to publish to their OKD dev namespace for a live test.
   Never deploy unprompted, and note that the `oc` CLI has to be authenticated
   against the cluster first.
