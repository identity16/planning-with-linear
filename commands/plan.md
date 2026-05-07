---
description: "Start Linear-backed planning. Creates a Linear Project, phase Issues, a Findings Document, and the kickoff Status Update for complex multi-step tasks."
disable-model-invocation: true
---

Invoke the planning-with-linear:planning-with-linear skill and follow it exactly as presented.

Steps the skill will guide you through:

1. Run `init-linear.sh` to guard against double-init.
2. Call `mcp__linear__list_teams` and ask the user which team to use.
3. Cache workflow state names via `mcp__linear__list_issue_statuses`.
4. Ensure the canonical labels exist: `phase`, `error`, `decision`, `blocker`. Create missing ones with `mcp__linear__create_issue_label`.
5. Create the Project with `mcp__linear__save_project` (use `templates/project-description.md`).
6. Create one phase Issue per phase via `mcp__linear__save_issue` (label `phase`, first phase state In Progress).
7. Create the Findings Document via `mcp__linear__save_document` linked to the project.
8. Post the kickoff Status Update via `mcp__linear__save_status_update` (`health: onTrack`).
9. Write `.planning/.active_linear` with `set-active-linear.sh write '<json>'`.
10. Tell the user the project URL.

If `mcp__linear__list_teams` is not available, surface a friendly prerequisite error pointing to https://linear.app/docs/mcp and stop.
