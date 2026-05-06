---
name: pr-ready
description: Prepare code changes for pull request readiness. Use when the user says /pr-ready, pr-ready, PR ready, pre-PR check, prepare PR, review all changes before PR, write missing tests before PR, or asks Codex to make current changes ready for review. Covers changed-file discovery, focused test coverage, code review, security review, build/test/format verification, and a concise readiness report.
---

# PR Ready

Run a scoped pre-PR quality pass over current changes.

## Workflow

1. Identify scope.
   - Inspect `git status --short`.
   - Inspect changed files with `git diff --name-only`, `git diff --name-only --staged`, and when relevant `git diff --name-only HEAD~1`.
   - Treat all unstaged and staged changes as in scope unless the user narrows scope.
   - Respect dirty worktree rules: do not revert or rewrite unrelated user changes.

2. Understand project validation.
   - Prefer repo docs and existing scripts: `package.json`, `Makefile`, `justfile`, CI configs, `*.sln`, `pyproject.toml`, `pubspec.yaml`, etc.
   - Select project-native commands over generic defaults.
   - If unclear, infer conservatively from existing tooling.

3. Run tests early.
   - Angular/TypeScript: prefer repo scripts, often `npm test -- --watch=false` or targeted test script.
   - .NET: `dotnet test`.
   - Python: `pytest`.
   - Flutter/Dart: `flutter test`.
   - Fix failing tests caused by in-scope changes before continuing.

4. Check test coverage for changed behavior.
   - For each changed production file, look for nearby tests: `*.spec.ts`, `*.test.ts`, `*_test.go`, `*_test.py`, `*_test.dart`, etc.
   - Verify changed functions, branches, edge cases, null/empty/boundary paths, and error paths are covered.
   - Add or update focused tests when coverage is missing.
   - Do not add low-value snapshot churn or broad brittle tests.

5. Review code deeply.
   - Prioritize correctness, regressions, missed requirements, data loss, race conditions, broken async flows, bad state transitions, and API/contract mismatches.
   - Check code quality: duplication, naming, error handling, magic values, complexity, unused code, dependency misuse, and consistency with local patterns.
   - Check security: injection, XSS/template injection, auth/authz gaps, unsafe input handling, sensitive data exposure, secret leakage, insecure dependency/config changes.
   - If subagents are explicitly authorized by the user, delegate an independent review of the changed files. Otherwise do the review locally.
   - Fix in-scope issues. For unrelated issues, report them unless they are high-severity and clearly block PR readiness.

6. Run verification after fixes.
   - Re-run relevant tests.
   - Run build/typecheck/lint if present or expected by the repo.
   - Typical commands: `npm run build`, `npm run lint`, `npm run typecheck`, `dotnet build`, `dotnet test`, `flutter analyze`, `flutter test`.
   - If a command cannot run due to missing services, env, credentials, or time, state exact blocker and what remains unverified.

7. Format last.
   - Use project formatter on changed files or repo formatter when that is the established pattern.
   - Examples: `npx prettier --write <changed-files>`, `dotnet format`, `black <changed-files>`, `dart format <changed-files>`.
   - After formatting, check `git diff --check` when applicable.

8. Final report.
   - State whether PR is ready.
   - Summarize fixes/tests added.
   - List verification commands and results.
   - List residual risks or blocked checks.
   - Mention any unrelated findings left for separate work.

## Rules

- Always run relevant tests; do not only inspect them.
- Write missing tests for changed behavior when practical.
- Keep fixes scoped to PR readiness and current changes.
- Follow existing codebase patterns.
- Do not create commits, branches, push, open PRs, or merge unless the user explicitly asks.
- Do not claim readiness if tests/build/lint are failing or unrun without a clear blocker.
