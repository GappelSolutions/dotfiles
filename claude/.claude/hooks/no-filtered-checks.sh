#!/usr/bin/env bash
# PreToolUse(Bash): reject test/build/lint/typecheck runs piped through head/tail/grep/…
# The filter hides the failure, so the agent reruns the check. Large output is saved to a file
# by the Bash tool anyway: filter that file instead. `| tee <file>` is allowed.
set -u

cmd=$(jq -r '.tool_input.command // empty' 2>/dev/null) || exit 0
[ -n "$cmd" ] || exit 0

# one line, redirections that contain `&` dropped so `&` only separates commands
cmd=${cmd//$'\n'/;}
cmd=${cmd//2>&1/}
cmd=${cmd//&>/>}
cmd=${cmd//|&/|}

pos='(^|[;&|(]|\btimeout +[0-9]+[smh]? +)[[:space:]]*([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]+ +)*'
check='(dotnet +(test|build)|(bunx?|npx|pnpm|yarn|npm)( +--bun)?( +(run|exec))?( +nx)? +[a-z:-]*(test|build|lint|typecheck|affected|e2e)|nx +(test|build|lint|affected|run|run-many|e2e)|cargo +(test|build|check|clippy)|go +(test|build|vet)|pytest|vitest|jest|tsc|ng +(test|build|lint))\b'
filter='\|[[:space:]]*(head|tail|grep|egrep|fgrep|rg|sed|awk|less|more)\b'

grep -qE "$pos$check[^;&]*$filter" <<<"$cmd" || exit 0
grep -qE "$pos$check[^;&]*\|[[:space:]]*tee\b" <<<"$cmd" && exit 0

cat >&2 <<'EOF'
Don't pipe test/build/lint/typecheck output to head/tail/grep/sed/awk: it hides the failure.
Run the check unfiltered. The Bash tool saves long output to a file and shows its path:
filter that file. Or `| tee <file>` and read the file.
EOF
exit 2
