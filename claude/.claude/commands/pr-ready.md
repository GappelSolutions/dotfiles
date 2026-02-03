# Pre-PR Code Quality Check

Perform a comprehensive pre-PR review of all changes including running tests, writing missing tests, deep code review, and verification.

## Workflow

Execute this workflow step by step:

### Step 1: Identify Changed Files

```bash
git diff --name-only HEAD~1
# Or for uncommitted changes:
git diff --name-only
git diff --name-only --staged
```

### Step 2: Run Tests

```bash
# For Angular projects:
npm test -- --watch=false

# For .NET projects:
dotnet test

# For Python projects:
pytest

# For Flutter projects:
flutter test
```

If tests fail, fix them before proceeding.

### Step 3: Check Test Coverage

For each changed file, verify:

1. **Does a test file exist?** Look for `*.spec.ts`, `*.test.ts`, `*_test.go`, `*_test.py`, `*_test.dart`, etc.
2. **Are the changed functions/methods tested?**
3. **Are edge cases covered?** (null, undefined, empty, boundary values)

If tests are missing or incomplete, **write them**.

### Step 4: Deep Code Review

Delegate to the `code-reviewer` agent for thorough analysis:

```
Task(subagent_type="oh-my-claudecode:code-reviewer", prompt="
Review all changed files for:

CODE QUALITY:
- DRY violations (duplicated code/logic that should be abstracted)
- Consistent naming (follow existing codebase conventions)
- Proper error handling (no swallowed errors, appropriate messages)
- Magic numbers/strings (should use constants or enums)
- Function/method complexity (extract if too long or nested)
- Unused code (imports, variables, methods, parameters)

SECURITY (OWASP Top 10):
- Injection vulnerabilities (SQL, command, XSS, template)
- Authentication/authorization gaps
- Input validation issues
- Sensitive data exposure (secrets, API keys, PII)
- Insecure dependencies

Provide severity-rated findings (CRITICAL/HIGH/MEDIUM/LOW) with specific file:line locations and fix recommendations.
")
```

Fix all CRITICAL and HIGH issues before proceeding.

### Step 5: Run Tests Again

After any fixes from code review:

```bash
npm test -- --watch=false
# or appropriate command for the project
```

Ensure all tests pass.

### Step 6: Run Build

```bash
# For Angular:
npm run build

# For .NET:
dotnet build

# For Flutter:
flutter build
```

Fix any build errors.

### Step 7: Run Formatter

Run the project's formatter on all changed files as the final step:

```bash
# For Angular/TypeScript projects:
npx prettier --write <changed-files>

# For .NET projects:
dotnet format

# For Python projects:
black <changed-files>

# For Flutter/Dart projects:
dart format <changed-files>
```

## Important Rules

- ALWAYS run tests, don't just check if they exist
- WRITE missing tests for changed code
- Fix CRITICAL and HIGH issues from code review before proceeding
- Fix failing tests before approving PR readiness
- Formatter runs last to ensure final code is properly formatted
- Follow existing codebase patterns
