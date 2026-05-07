#!/usr/bin/env bash
# linear-catchup.sh — Detect repo activity since the last Linear sync.
#
# Replaces the original session-catchup.py. The Linear server is the source of
# truth, so we don't parse session JSONL anymore. Instead we ask: did the local
# repo change since the model last posted to Linear? If yes, the model should
# go reconcile (post a Status Update, comment on the active phase issue, or
# update the Findings document).
#
# Always exits 0.

set -e

ACTIVE_FILE=".planning/.active_linear"

if [ ! -f "$ACTIVE_FILE" ]; then
    exit 0
fi

LAST_SYNCED=$(grep -oE '"last_synced_at"[[:space:]]*:[[:space:]]*"[^"]*"' "$ACTIVE_FILE" 2>/dev/null \
    | head -1 \
    | sed -E 's/.*"last_synced_at"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/')

if [ -z "$LAST_SYNCED" ]; then
    echo "[planning-with-linear] last_synced_at not set in .active_linear. Run /sync to baseline."
    exit 0
fi

if ! command -v git >/dev/null 2>&1; then
    exit 0
fi

if ! git rev-parse --git-dir >/dev/null 2>&1; then
    exit 0
fi

COMMITS=$(git log --since="$LAST_SYNCED" --oneline 2>/dev/null | wc -l | tr -d ' ')
DIRTY=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')

if [ "$COMMITS" -eq 0 ] && [ "$DIRTY" -eq 0 ]; then
    exit 0
fi

echo "[planning-with-linear] CATCHUP: repo activity since last Linear sync ($LAST_SYNCED):"
[ "$COMMITS" -gt 0 ] && echo "  - $COMMITS commit(s) since last sync"
[ "$DIRTY" -gt 0 ]   && echo "  - $DIRTY uncommitted change(s) in working tree"
echo ""
if [ "$COMMITS" -gt 0 ]; then
    echo "Recent commits:"
    git log --since="$LAST_SYNCED" --oneline 2>/dev/null | head -10 | sed 's/^/  /'
    echo ""
fi
echo "Reconcile: call mcp__linear__list_comments and mcp__linear__get_status_updates,"
echo "decide what to log via mcp__linear__save_comment / mcp__linear__save_status_update,"
echo "then run /sync to update last_synced_at."
exit 0
