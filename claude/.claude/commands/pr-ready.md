# Pre-PR Code Quality Check

Perform a comprehensive pre-PR review of all changes including running and writing tests.

## Workflow

Execute this workflow step by step:

### Step 1: Identify Changed Files

```bash
git diff --name-only HEAD~1
# Or for uncommitted changes:
git diff --name-only
git diff --name-only --staged
```

### Step 2: Run Formatter

Run the project's formatter on all changed files:

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

### Step 3: Run Tests

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

### Step 4: Check Test Coverage

For each changed file, verify:

1. **Does a test file exist?** Look for `*.spec.ts`, `*.test.ts`, `*_test.go`, `*_test.py`, `*_test.dart`, etc.
2. **Are the changed functions/methods tested?**
3. **Are edge cases covered?** (null, undefined, empty, boundary values)

If tests are missing or incomplete, **write them**.

### Step 5: Code Review Checklist

Review all changed code for:

1. **No Comments** - Remove ALL comments. Code must be self-explanatory.
2. **DRY Principle** - No duplicated code/logic that should be abstracted.
3. **Consistent Naming** - Follow existing codebase conventions.
4. **Proper Error Handling** - No swallowed errors, appropriate error messages.
5. **No Magic Numbers/Strings** - Use constants or enums.

### Step 5.5: Check for Unused Code (Manual Review)

**CAUTION**: Detecting unused code in Angular/TypeScript requires careful analysis since:
- Template bindings make static analysis unreliable
- Services may be injected dynamically
- Exported members may be used by other modules

For each changed file, manually check for:

1. **Unused imports** - Imports at the top that aren't referenced in the file
2. **Unused private methods** - Private methods not called anywhere in the class
3. **Unused variables/signals** - Declared but never read
4. **Unused parameters** - Function parameters that are never used (prefix with `_` if intentionally unused)
5. **Dead code** - Code after return statements, unreachable branches

```bash
# TypeScript/Angular - check for unused exports (be careful, may have false positives):
npx ts-prune --error 2>/dev/null | head -20

# Or use ESLint with unused rules:
npx eslint --rule '@typescript-eslint/no-unused-vars: error' <changed-files> 2>/dev/null
```

**Important**: Be conservative - don't remove code that might be used in templates, tests, or other modules. When in doubt, leave it and flag for review.

### Step 6: Security Review

Check for security vulnerabilities:

- **Injection Vulnerabilities**: SQL injection, command injection, XSS, template injection
- **Authentication/Authorization**: Proper auth checks on sensitive operations, no hardcoded credentials
- **Input Validation**: All user inputs validated and sanitized before use
- **Sensitive Data Exposure**: No secrets, API keys, tokens, or PII logged or exposed
- **Insecure Dependencies**: Known vulnerable packages or outdated security-critical libraries
- **CORS/CSRF**: Proper cross-origin and CSRF protections where applicable
- **Path Traversal**: File operations checked for directory traversal vulnerabilities
- **Cryptography**: Proper use of crypto (no weak algorithms, proper key management)
- **Error Handling**: Errors don't leak sensitive information (stack traces, internal paths)

### Step 7: Run Tests Again

After any fixes or new tests:

```bash
npm test -- --watch=false
# or appropriate command for the project
```

Ensure all tests pass before completing.

### Step 8: Run Build

```bash
# For Angular:
npm run build

# For .NET:
dotnet build

# For Flutter:
flutter build
```

Fix any build errors.

## Important Rules

- ALWAYS run tests, don't just check if they exist
- WRITE missing tests for changed code
- Fix failing tests before approving PR readiness
- Run formatter before committing
- Remove ALL comments from code
- Follow existing codebase patterns
