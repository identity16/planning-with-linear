---
description: "Refresh .planning/.active_linear from Linear. Use after editing issues in the Linear UI, or whenever the cache feels stale."
---

Re-fetch the active Linear project and rewrite `.planning/.active_linear` with current state.

Steps:

1. Read `.planning/.active_linear` to get `project_id` and `team_id`. If absent, tell the user to run `/plan` and stop.
2. Call `mcp__linear__get_project({ projectId })` for the project name and URL.
3. Call `mcp__linear__list_issues({ projectId, labels: ["phase"] })` to get current phase issues with their workflow states.
4. Call `mcp__linear__list_issue_statuses({ teamId })` if `states` is missing from the cache.
5. Construct the JSON payload following the schema in `skills/planning-with-linear/reference.md`. Include `last_synced_at` set to the current ISO 8601 UTC timestamp. Do **not** cache issue relations — fetch them fresh when needed.
6. Write it via `set-active-linear.sh write '<json>'`.
7. Print a one-line confirmation: project URL + phase count + active phase ID. If any `Backlog` phases exist, also fetch `mcp__linear__get_issue({ id, includeRelations: true })` for each and call out any whose `blockedBy` issues are all `Done` as "ready to promote".

This command does not post anything to Linear — it only reads. Safe to run anytime.
