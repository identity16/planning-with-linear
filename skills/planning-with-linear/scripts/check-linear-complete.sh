#!/usr/bin/env bash
# check-linear-complete.sh — Stop hook helper.
#
# Reads .planning/.active_linear and reports a cached completion summary.
# Always exits 0 — this is a Stop-hook reminder, not a gate.
#
# The cache may be stale. The output explicitly recommends /sync.

set -e

ACTIVE_FILE=".planning/.active_linear"

if [ ! -f "$ACTIVE_FILE" ]; then
    echo "[planning-with-linear] No active Linear project — no planning session to summarize."
    exit 0
fi

# Count states inside phase_issues only (skip the states-map block).
PHASES_BLOCK=$(awk '/"phase_issues"[[:space:]]*:[[:space:]]*\[/,/\]/' "$ACTIVE_FILE" 2>/dev/null)

TOTAL=$(echo "$PHASES_BLOCK" | grep -oE '"state"[[:space:]]*:[[:space:]]*"[^"]*"' | wc -l | tr -d ' ')
DONE=$(echo "$PHASES_BLOCK" | grep -oiE '"state"[[:space:]]*:[[:space:]]*"(done|completed|shipped|closed)"' | wc -l | tr -d ' ')
IN_PROG=$(echo "$PHASES_BLOCK" | grep -oiE '"state"[[:space:]]*:[[:space:]]*"(in[_ ]?progress|started|doing|active)"' | wc -l | tr -d ' ')
TODO=$(( TOTAL - DONE - IN_PROG ))
[ "$TODO" -lt 0 ] && TODO=0

if [ "$TOTAL" -eq 0 ]; then
    echo "[planning-with-linear] .active_linear present but no phase_issues found. Run /sync to refresh the cache."
    exit 0
fi

if [ "$DONE" -eq "$TOTAL" ]; then
    echo "[planning-with-linear] ALL PHASES COMPLETE ($DONE/$TOTAL, cached). If the user has more work, create new Issues in the same project (don't reopen Done ones)."
else
    echo "[planning-with-linear] In progress: $DONE/$TOTAL phases complete (cached, may be stale)."
    [ "$IN_PROG" -gt 0 ] && echo "[planning-with-linear] $IN_PROG phase(s) currently in progress."
    [ "$TODO" -gt 0 ]    && echo "[planning-with-linear] $TODO phase(s) still to start."
    echo "[planning-with-linear] Run /sync to refresh the cache from Linear, or post a Status Update before stopping."
fi
exit 0
