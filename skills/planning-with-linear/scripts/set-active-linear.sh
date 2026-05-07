#!/usr/bin/env bash
# set-active-linear.sh — Write or update .planning/.active_linear.
#
# Usage:
#   set-active-linear.sh write <json-payload>
#       Write the full JSON payload (string) to .planning/.active_linear.
#       The model is expected to construct the JSON from MCP responses.
#   set-active-linear.sh clear
#       Remove .planning/.active_linear (e.g. before starting a fresh project).
#   set-active-linear.sh show
#       Print the current contents (or "no active project" if absent).
#
# This script does not validate the JSON shape — that's the model's responsibility.
# It only manages the file.

set -e

PLAN_DIR=".planning"
ACTIVE_FILE="$PLAN_DIR/.active_linear"

cmd="${1:-show}"

case "$cmd" in
    write)
        shift
        if [ -z "${1:-}" ]; then
            echo "[planning-with-linear] set-active-linear.sh write requires a JSON payload as the next argument." >&2
            exit 1
        fi
        mkdir -p "$PLAN_DIR"
        printf '%s' "$1" > "$ACTIVE_FILE"
        echo "[planning-with-linear] Wrote $ACTIVE_FILE"
        ;;
    clear)
        if [ -f "$ACTIVE_FILE" ]; then
            rm "$ACTIVE_FILE"
            echo "[planning-with-linear] Cleared $ACTIVE_FILE"
        else
            echo "[planning-with-linear] No active project to clear."
        fi
        ;;
    show|"")
        if [ -f "$ACTIVE_FILE" ]; then
            cat "$ACTIVE_FILE"
        else
            echo "[planning-with-linear] No active project (.planning/.active_linear absent)."
        fi
        ;;
    *)
        echo "[planning-with-linear] Unknown command: $cmd. Use write|clear|show." >&2
        exit 1
        ;;
esac
