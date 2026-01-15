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
OUTPUT+="${GRAY} | ${RESET}"
OUTPUT+="${MAGENTA}${DUR_FMT}${RESET}"

# Add cost if > 0
if [ "$(echo "$COST > 0" | bc)" -eq 1 ]; then
    COST_FMT=$(printf "$%.2f" $COST)
    OUTPUT+="${GRAY} | ${RESET}${GREEN}${COST_FMT}${RESET}"
fi

echo -e "$OUTPUT"
