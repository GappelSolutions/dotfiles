#!/bin/bash
input=$(cat)

# Extract values using jq
MODEL=$(echo "$input" | jq -r '.model.display_name // "Claude"')
DIR=$(echo "$input" | jq -r '.cwd // "."' | xargs basename)
INPUT_TOKENS=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
OUTPUT_TOKENS=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
CONTEXT_SIZE=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
DURATION=$(echo "$input" | jq -r '.session.duration_seconds // 0')

# Get git branch
BRANCH=""
if git -C "$(echo "$input" | jq -r '.cwd // "."')" rev-parse --git-dir >/dev/null 2>&1; then
    BRANCH=$(git -C "$(echo "$input" | jq -r '.cwd // "."')" branch --show-current 2>/dev/null)
    DIRTY=""
    if ! git -C "$(echo "$input" | jq -r '.cwd // "."')" diff --quiet 2>/dev/null || \
       ! git -C "$(echo "$input" | jq -r '.cwd // "."')" diff --cached --quiet 2>/dev/null; then
        DIRTY="*"
    fi
    BRANCH=" ${BRANCH}${DIRTY}"
fi

# Calculate context percentage
CURRENT=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // 0')
CACHE_CREATE=$(echo "$input" | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0')
CACHE_READ=$(echo "$input" | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')
TOTAL_CURRENT=$((CURRENT + CACHE_CREATE + CACHE_READ))
if [ "$CONTEXT_SIZE" -gt 0 ]; then
    PERCENT=$((TOTAL_CURRENT * 100 / CONTEXT_SIZE))
else
    PERCENT=0
fi

# Format tokens (K format)
format_tokens() {
    local n=$1
    if [ "$n" -ge 1000 ]; then
        echo "$(echo "scale=1; $n/1000" | bc)K"
    else
        echo "$n"
    fi
}

IN_FMT=$(format_tokens $INPUT_TOKENS)
OUT_FMT=$(format_tokens $OUTPUT_TOKENS)

# Format duration
format_duration() {
    local secs=$1
    local mins=$((secs / 60))
    local s=$((secs % 60))
    if [ "$mins" -gt 0 ]; then
        printf "%dm %02ds" $mins $s
    else
        printf "%ds" $s
    fi
}

DUR_FMT=$(format_duration $DURATION)

# 5h / weekly usage % via OAuth usage API, cached to avoid a network call per render
CACHE_FILE="/tmp/.claude-usage-cache-$(id -u)"
CACHE_TTL=300
USAGE_JSON=""
if [ -f "$CACHE_FILE" ] && [ $(( $(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0) )) -lt "$CACHE_TTL" ]; then
    USAGE_JSON=$(cat "$CACHE_FILE")
else
    TOKEN=$(jq -r '.claudeAiOauth.accessToken // empty' ~/.claude/.credentials.json 2>/dev/null)
    if [ -n "$TOKEN" ]; then
        USAGE_JSON=$(curl -s --max-time 2 -H "Authorization: Bearer $TOKEN" -H "anthropic-beta: oauth-2025-04-20" "https://api.anthropic.com/api/oauth/usage" 2>/dev/null)
        [ -n "$USAGE_JSON" ] && echo "$USAGE_JSON" > "$CACHE_FILE"
    fi
fi
FIVE_H=$(echo "$USAGE_JSON" | jq -r '.five_hour.utilization // empty' 2>/dev/null)
WEEK=$(echo "$USAGE_JSON" | jq -r '.seven_day.utilization // empty' 2>/dev/null)
FIVE_H_RESET=$(echo "$USAGE_JSON" | jq -r '.five_hour.resets_at // empty' 2>/dev/null)
FIVE_H_LEFT=""
if [ -n "$FIVE_H_RESET" ]; then
    RESET_EPOCH=$(date -d "$FIVE_H_RESET" +%s 2>/dev/null)
    NOW_EPOCH=$(date +%s)
    if [ -n "$RESET_EPOCH" ]; then
        SECS_LEFT=$((RESET_EPOCH - NOW_EPOCH))
        if [ "$SECS_LEFT" -gt 0 ]; then
            H_LEFT=$((SECS_LEFT / 3600))
            M_LEFT=$(((SECS_LEFT % 3600) / 60))
            FIVE_H_LEFT=$(printf "%dh%02dm" $H_LEFT $M_LEFT)
        fi
    fi
fi

# Context color based on usage
if [ "$PERCENT" -lt 60 ]; then
    CTX_COLOR="\033[32m"  # green
elif [ "$PERCENT" -lt 80 ]; then
    CTX_COLOR="\033[33m"  # yellow
else
    CTX_COLOR="\033[31m"  # red
fi

# Build output with ANSI colors
RESET="\033[0m"
WHITE="\033[1;37m"
CYAN="\033[36m"
GREEN="\033[32m"
MAGENTA="\033[35m"
GRAY="\033[90m"

OUTPUT="${CYAN}${MODEL}${RESET}"
OUTPUT+="${GRAY} | ${RESET}"
OUTPUT+="${WHITE}${DIR}${RESET}"
if [ -n "$BRANCH" ]; then
    OUTPUT+="${GREEN}${BRANCH}${RESET}"
fi
OUTPUT+="${GRAY} | ${RESET}"
OUTPUT+="${CYAN}↑${IN_FMT}${RESET} ${MAGENTA}↓${OUT_FMT}${RESET}"
OUTPUT+="${GRAY} | ${RESET}"
OUTPUT+="${CTX_COLOR}${PERCENT}%${RESET}"
if [ -n "$FIVE_H" ] || [ -n "$WEEK" ]; then
    OUTPUT+="${GRAY} | ${RESET}"
    [ -n "$FIVE_H" ] && OUTPUT+="${CYAN}5h:${FIVE_H%.*}%${RESET}"
    [ -n "$FIVE_H_LEFT" ] && OUTPUT+="${GRAY}(${FIVE_H_LEFT})${RESET}"
    [ -n "$FIVE_H" ] && [ -n "$WEEK" ] && OUTPUT+=" "
    [ -n "$WEEK" ] && OUTPUT+="${MAGENTA}7d:${WEEK%.*}%${RESET}"
fi
OUTPUT+="${GRAY} | ${RESET}"
OUTPUT+="${MAGENTA}${DUR_FMT}${RESET}"

# Add cost if > 0
if [ "$(echo "$COST > 0" | bc)" -eq 1 ]; then
    COST_FMT=$(printf "$%.2f" $COST)
    OUTPUT+="${GRAY} | ${RESET}${GREEN}${COST_FMT}${RESET}"
fi

echo -e "$OUTPUT"
