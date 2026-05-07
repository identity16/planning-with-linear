---
description: "Show the current Linear-backed planning status: project URL, phase issues with workflow states, recent status updates, and any error-labeled issues."
---

Read `.planning/.active_linear` for the cached pointer, then fetch authoritative state from Linear.

## What to show

1. **Project**: name, URL, team key (from cache + `mcp__linear__get_project`).
2. **Phase issues**: each issue's ID, title, state — fetched fresh via `mcp__linear__list_issues({ projectId, includeArchived: false })`.
3. **Active phase**: the issue currently in the team's "started" state (e.g. "In Progress").
4. **Recent status updates**: last 3 via `mcp__linear__get_status_updates({ projectId })`.
5. **Errors and blockers**: count of issues in the project with the `error` or `blocker` label.

After fetching, refresh `.planning/.active_linear` via `set-active-linear.sh write '<json>'` so the cache is fresh for hooks.

## Status icons (state → icon)

- backlog / todo → ⏸️
- in_progress / started → 🔄
- done / completed → ✅
- canceled → ❌
- blocker label present → 🚧

## Output format

```
📋 Linear Plan: <project_name>
URL: <project_url>

Active: <issue_id> — <issue_title>
Phases (X/N done):
  ✅ ENG-101 Phase 1: Discovery
  🔄 ENG-102 Phase 2: Design   ← you are here
  ⏸️ ENG-103 Phase 3: Implement

Recent updates:
  - 2026-05-07 onTrack: Wired up theme switching.
  - 2026-05-06 onTrack: Toggle component done.

Errors logged: 1   Blockers: 0
```

## If `.planning/.active_linear` is absent

```
📋 No active Linear plan in this repo.
Run /plan to start one.
```

## If Linear MCP is unavailable

Fall back to the cache and label everything "(cached, may be stale)". Recommend reconnecting Linear MCP and running `/sync`.

Keep it brief — this is a quick "where am I?" check.
