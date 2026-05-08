---
description: "Start Linear-backed planning. Creates a Linear Project, phase Issues, a Findings Document, and the kickoff Status Update for complex multi-step tasks."
disable-model-invocation: true
---

Invoke the planning-with-linear:planning-with-linear skill and follow it exactly as presented.

Steps the skill will guide you through:

1. Run `init-linear.sh` to guard against double-init.
2. Call `mcp__linear__list_teams` and ask the user which team to use.
3. Cache workflow state names via `mcp__linear__list_issue_statuses`. Capture `triage` (if present), `backlog`, `todo`, `in_progress`, `done`, `canceled`.
4. Ensure the canonical labels exist: `phase`, `error`, `decision`, `blocker`. Create missing ones with `mcp__linear__create_issue_label`. Do **not** create a `triage` label — Triage is a workflow state, not a label.
5. Create the Project with `mcp__linear__save_project` (use `templates/project-description.md`).
6. Create one phase Issue per phase via `mcp__linear__save_issue` (label `phase`, body from `templates/phase-issue-body.md`). Initial states:
   - First phase → `In Progress`.
   - Phases that are immediately actionable (no prerequisites) → `Todo`.
   - Phases that depend on a prior phase or are post-MVP stretch work → `Backlog`.
7. **Wire phase dependencies as Linear issue relations.** After all phase issues exist, walk the dependency graph and call `mcp__linear__save_issue({ id, blockedBy: [<blocker ids>] })` for each phase that has prerequisites. For a linear chain this is just `Phase N blockedBy Phase N-1`; for branching plans, list every direct prerequisite. Do **not** encode dependencies as prose in the issue body — `blockedBy` is the source of truth. Use `relatedTo` for soft cross-links that don't imply ordering.
8. Create the Findings Document via `mcp__linear__save_document` linked to the project.
9. Post the kickoff Status Update via `mcp__linear__save_status_update` (`health: onTrack`). The body should name the active phase and list the next-up phases (Todo + Backlog with their blockers, e.g. "Phase 3 blockedBy Phase 2").
10. Write `.planning/.active_linear` with `set-active-linear.sh write '<json>'`. Do **not** cache relations in the JSON — they're cheap to fetch and would drift.
11. Tell the user the project URL.

If `mcp__linear__list_teams` is not available, surface a friendly prerequisite error pointing to https://linear.app/docs/mcp and stop.
