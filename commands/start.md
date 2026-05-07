---
description: "Resume or start a Linear-backed planning session. Loads .planning/.active_linear, re-fetches the project from Linear, and orients the model to the current phase."
disable-model-invocation: true
---

Invoke the planning-with-linear:planning-with-linear skill and follow it exactly as presented.

If `.planning/.active_linear` exists:
1. Read it for the cached project ID and phase summary.
2. Call `mcp__linear__get_project` and `mcp__linear__list_issues` (filter by project) for authoritative state.
3. Call `mcp__linear__get_status_updates` for the recent narrative.
4. Identify the in-progress phase issue and continue.
5. Optionally run `linear-catchup.sh` to surface any unsynced repo activity.

If `.planning/.active_linear` is absent, run `/plan` instead — there's no active project to resume.
