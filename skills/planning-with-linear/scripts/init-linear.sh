#!/usr/bin/env bash
# init-linear.sh — Pre-flight check for /plan.
#
# This script does NOT call Linear. The model does that via MCP, following
# the steps in SKILL.md. The script's job is to:
#   1. Decide whether init is safe (refuse to clobber an existing active project).
#   2. Print a checklist the model can follow.
#   3. Make sure .planning/ exists.
#
# Always exits 0 — the slash command and model handle next steps.

set -e

PLAN_DIR=".planning"
ACTIVE_FILE="$PLAN_DIR/.active_linear"

mkdir -p "$PLAN_DIR"

if [ -f "$ACTIVE_FILE" ]; then
    echo "[planning-with-linear] An active Linear project already exists for this repo:"
    echo ""
    cat "$ACTIVE_FILE" 2>/dev/null | head -40
    echo ""
    echo "[planning-with-linear] Options:"
    echo "  1. Open the existing project (already active — just continue)."
    echo "  2. Add new phases: call mcp__linear__save_issue against the existing projectId."
    echo "  3. Start a fresh project: remove .planning/.active_linear first, then re-run /plan."
    echo ""
    echo "[planning-with-linear] Refusing to silently overwrite. Exiting."
    exit 0
fi

cat <<'EOF'
[planning-with-linear] No active Linear project for this repo. Starting init.

Model checklist (executed via MCP, not by this script):
  1. mcp__linear__list_teams             → present teams to user, ask them to pick one.
  2. mcp__linear__list_issue_statuses    → cache state names (todo / in_progress / done) for the team.
  3. mcp__linear__list_issue_labels      → ensure labels exist; create missing ones with mcp__linear__create_issue_label:
       - phase, error, decision, blocker
  4. mcp__linear__save_project           → create the project from templates/project-description.md.
  5. mcp__linear__save_issue (xN)        → create one issue per phase, label "phase", first phase state="In Progress".
  6. mcp__linear__save_document          → create the Findings document (templates/findings-document.md), linked via projectId.
  7. mcp__linear__save_status_update     → kickoff Status Update, health=onTrack.
  8. set-active-linear.sh <project_id>   → write .planning/.active_linear with the cached summary.

If mcp__linear__list_teams fails: confirm Linear MCP is registered. See https://linear.app/docs/mcp.
EOF
exit 0
