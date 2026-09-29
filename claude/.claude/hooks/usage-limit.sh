#!/usr/bin/env bash
# Per-session usage cap. Put `$limit 80%` (5h, default), `$limit 7d 50%` or `$limit off` on its own
# line in a prompt; once the window's utilization reaches the cap, the next tool call stops the session.
# UserPromptSubmit: arm/disarm. PreToolUse: check (usage cached 60s, shared with the statusline).
set -u

input=$(cat)
event=$(jq -r '.hook_event_name // empty' <<<"$input")
session=$(jq -r '.session_id // empty' <<<"$input")
[ -n "$session" ] || exit 0

state_dir="${XDG_RUNTIME_DIR:-/tmp}/claude-usage-limit"
state="$state_dir/$session"
cache="/tmp/.claude-usage-cache-$(id -u)"
ttl=60

# prints "<utilization> <resets_at>" for window 5h|7d, empty on failure (fail open)
usage() {
  local key json
  [ "$1" = 5h ] && key=five_hour || key=seven_day
  if [ -f "$cache" ] && [ $(($(date +%s) - $(stat -c %Y "$cache" 2>/dev/null || echo 0))) -lt "$ttl" ]; then
    json=$(cat "$cache")
  else
    local token
    token=$(jq -r '.claudeAiOauth.accessToken // empty' ~/.claude/.credentials.json 2>/dev/null)
    [ -n "$token" ] || return
    json=$(curl -s --max-time 3 -H "Authorization: Bearer $token" -H "anthropic-beta: oauth-2025-04-20" \
      https://api.anthropic.com/api/oauth/usage 2>/dev/null)
    jq -e ".$key.utilization" <<<"$json" >/dev/null 2>&1 || return
    printf '%s' "$json" >"$cache"
  fi
  jq -r ".$key | select(.utilization != null) | \"\(.utilization) \(.resets_at // \"?\")\"" <<<"$json" 2>/dev/null
}

over() { awk -v u="$1" -v l="$2" 'BEGIN { exit !(u >= l) }'; }

case "$event" in
UserPromptSubmit)
  line=$(jq -r '.prompt // empty' <<<"$input" | grep -m1 -E '^\s*\$limit\b') || exit 0
  if grep -qE '\boff\b' <<<"$line"; then
    rm -f "$state"
    jq -n '{hookSpecificOutput: {hookEventName: "UserPromptSubmit",
      additionalContext: "usage-limit hook: `$limit off` disarmed the cap. Not a task for you."}}'
    exit 0
  fi
  pct=$(grep -oE '[0-9]+(\.[0-9]+)?%' <<<"$line" | head -1 | tr -d %)
  [ -n "$pct" ] || { jq -n '{decision: "block", reason: "usage-limit: want `$limit 80%`, `$limit 7d 50%` or `$limit off`"}'; exit 0; }
  grep -qE '\b7d\b' <<<"$line" && win=7d || win=5h
  read -r util reset <<<"$(usage "$win")"
  if [ -n "${util:-}" ] && over "$util" "$pct"; then
    jq -n --arg r "usage-limit: $win already at $util% (cap $pct%, resets $reset)" '{decision: "block", reason: $r}'
    exit 0
  fi
  mkdir -p "$state_dir"
  echo "$win $pct" >"$state"
  jq -n --arg c "usage-limit hook armed: session stops once $win usage reaches $pct% (now ${util:-?}%). The \`\$limit\` line is not a task for you; keep working normally." \
    '{hookSpecificOutput: {hookEventName: "UserPromptSubmit", additionalContext: $c}}'
  ;;
PreToolUse)
  [ -f "$state" ] || exit 0
  read -r win pct <"$state"
  read -r util reset <<<"$(usage "$win")"
  [ -n "${util:-}" ] && over "$util" "$pct" || exit 0
  rm -f "$state"
  jq -n --arg r "usage-limit: $win usage $util% reached cap $pct% (resets $reset). Session stopped." \
    '{continue: false, stopReason: $r, systemMessage: $r}'
  ;;
esac
exit 0
