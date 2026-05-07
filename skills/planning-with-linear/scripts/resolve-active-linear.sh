#!/usr/bin/env bash
# resolve-active-linear.sh — Print the active Linear project pointer for hooks.
#
# Resolution order:
#   1. $LINEAR_PROJECT_ID env var (if set, used verbatim — no cache lookup).
#   2. .planning/.active_linear (the cached JSON written by set-active-linear.sh).
#   3. Nothing — silent exit.
#
# Output format (human-readable, fed into hook stdout):
#   [planning-with-linear] active project: <id>
#   url: <project_url>
#   phases (cached, may be stale): N/M complete
#     - ENG-101 [Done]      Phase 1: Discovery
#     - ENG-102 [In Progress] Phase 2: Design
#     ...
#   Reminder: call mcp__linear__get_project / list_issues for fresh state before deciding.
#
# Flags:
#   --short  one-liner suitable for PreToolUse (project URL + active phase only).
#
# This script never calls Linear. It only reads local files.
# Always exits 0 to avoid blocking hooks on parse failures.

set -e

ACTIVE_FILE=".planning/.active_linear"
SHORT=0

while [ $# -gt 0 ]; do
    case "$1" in
        --short) SHORT=1; shift ;;
        *) shift ;;
    esac
done

# Path 1: env var override
if [ -n "${LINEAR_PROJECT_ID:-}" ]; then
    echo "[planning-with-linear] active project (from \$LINEAR_PROJECT_ID): $LINEAR_PROJECT_ID"
    echo "Reminder: call mcp__linear__get_project for fresh state before deciding."
    exit 0
fi

# Path 2: cache file
if [ ! -f "$ACTIVE_FILE" ]; then
    exit 0
fi

extract() {
    # Very small JSON value extractor for top-level string keys: extract <key>
    local key="$1"
    grep -o "\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$ACTIVE_FILE" 2>/dev/null \
        | head -1 \
        | sed -E "s/.*\"$key\"[[:space:]]*:[[:space:]]*\"([^\"]*)\".*/\1/"
}

PROJECT_ID="$(extract project_id)"
PROJECT_URL="$(extract project_url)"
PROJECT_NAME="$(extract project_name)"

if [ -z "$PROJECT_ID" ]; then
    # File exists but is malformed — surface that, don't crash.
    echo "[planning-with-linear] .active_linear present but unparseable. Run /sync to refresh."
    exit 0
fi

# Find the in-progress phase by extracting from phase_issues array.
# Heuristic: scan for {"id": "...", "title": "...", "state": "In Progress"} entries
# (uses the team's cached state name; default falls back to literal "In Progress").
ACTIVE_PHASE_LINE=$(grep -oE '\{[^}]*"state"[[:space:]]*:[[:space:]]*"[^"]*"[^}]*\}' "$ACTIVE_FILE" 2>/dev/null \
    | grep -iE '"state"[[:space:]]*:[[:space:]]*"(in[_ ]?progress|started|doing|active)"' \
    | head -1)

ACTIVE_PHASE_ID=$(echo "$ACTIVE_PHASE_LINE" | sed -nE 's/.*"id"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p')
ACTIVE_PHASE_TITLE=$(echo "$ACTIVE_PHASE_LINE" | sed -nE 's/.*"title"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p')

if [ "$SHORT" = "1" ]; then
    echo "[planning-with-linear] $PROJECT_ID — active: ${ACTIVE_PHASE_ID:-?} ${ACTIVE_PHASE_TITLE:-(no in-progress phase)}"
    exit 0
fi

# Long form
echo "[planning-with-linear] active project: $PROJECT_ID${PROJECT_NAME:+ ($PROJECT_NAME)}"
[ -n "$PROJECT_URL" ] && echo "url: $PROJECT_URL"

# Count phase states from inside the phase_issues block (works on single-line JSON too).
PHASES_BLOCK=$(sed -nE 's/.*"phase_issues"[[:space:]]*:[[:space:]]*\[(.*)\][^]]*$/\1/p' "$ACTIVE_FILE" 2>/dev/null)
if [ -z "$PHASES_BLOCK" ]; then
    PHASES_BLOCK=$(awk '/"phase_issues"[[:space:]]*:[[:space:]]*\[/,/\]/' "$ACTIVE_FILE" 2>/dev/null)
fi
TOTAL=$(echo "$PHASES_BLOCK" | grep -oE '"state"[[:space:]]*:[[:space:]]*"[^"]*"' | wc -l | tr -d ' ')
DONE=$(echo "$PHASES_BLOCK" | grep -oiE '"state"[[:space:]]*:[[:space:]]*"(done|completed|shipped|closed)"' | wc -l | tr -d ' ')

if [ "$TOTAL" -gt 0 ]; then
    echo "phases (cached, may be stale): $DONE/$TOTAL complete"
fi

if [ -n "$ACTIVE_PHASE_ID" ]; then
    echo "active phase: $ACTIVE_PHASE_ID — $ACTIVE_PHASE_TITLE"
fi

echo "Reminder: cache is a hint. Call mcp__linear__get_project and mcp__linear__list_issues for authoritative state before deciding."
exit 0
