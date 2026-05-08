---
description: "Resume or start a Linear-backed planning session. Loads .planning/.active_linear, re-fetches the project from Linear, and orients the model to the current phase."
disable-model-invocation: true
---

Invoke the planning-with-linear:planning-with-linear skill and follow it exactly as presented.

If `.planning/.active_linear` exists:
1. Read it for the cached project ID and phase summary.
2. Call `mcp__linear__get_project` and `mcp__linear__list_issues({ projectId })` for authoritative state.
3. For the in-progress phase, call `mcp__linear__get_issue({ id, includeRelations: true })` so its `blockedBy` / `blocks` / `relatedTo` are visible in context. (Relations are not on the default `get_issue` payload and are not cached locally.)
4. **Check backlog readiness.** For each phase in `state=Backlog`, call `mcp__linear__get_issue({ id, includeRelations: true })`. If every `blockedBy` issue is `Done`, surface that phase as "ready to promote" and ask the user whether to move it to `Todo` (`save_issue({ id, state: states.todo })`).
5. **Surface the triage queue.** Call `mcp__linear__list_issues({ projectId, state: states.triage })`. If non-empty, list the items and remind the user they should be sorted at the next phase boundary (promote, defer to Backlog with `blockedBy` wired, or close as `duplicateOf`).
6. Call `mcp__linear__get_status_updates` for the recent narrative.
7. Optionally run `linear-catchup.sh` to surface any unsynced repo activity.

If `.planning/.active_linear` is absent, run `/plan` instead — there's no active project to resume.
