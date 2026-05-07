# Reference: Linear as External Memory

This skill is a fork of `planning-with-files`, which adapted Manus's "filesystem as external memory" pattern. The same context-engineering principles apply — only the storage backend changed.

## Why Linear

Local markdown files are great working memory but bad shared state. Linear gives you:
- **Native workflow states** on every Issue (Backlog / Todo / In Progress / In Review / Done / Cancelled) — no more counting checkboxes in a markdown table.
- **First-class IDs and URLs** for every entity, so the cache in `.planning/.active_linear` only needs string IDs.
- **Append-only Status Updates** with a `health` field (`onTrack` / `atRisk` / `offTrack`) — the project version of `progress.md`.
- **Comments** that thread under an issue, so the failure ledger sits next to the work it describes.
- **Documents** that survive cycle and project rollovers, for long-form research.

Manus's principles still hold; only the writes target a different surface.

## Core Mapping (read this if nothing else)

| Concept | Linear surface | Write MCP | Read MCP |
|---|---|---|---|
| Goal of the task | Project description | `mcp__linear__save_project` | `mcp__linear__get_project` |
| One phase of work | Issue (with `phase` label) | `mcp__linear__save_issue` | `mcp__linear__get_issue`, `mcp__linear__list_issues` |
| Phase status | Issue workflow state | `mcp__linear__save_issue` (`state`) | `mcp__linear__list_issue_statuses` (cache at init) |
| Sub-tasks of a phase | Sub-issue (`parentId`) | `mcp__linear__save_issue` | `mcp__linear__list_issues` |
| Research, requirements, technical decisions | Linked Document | `mcp__linear__save_document` | `mcp__linear__get_document` |
| Session log (high-level) | Project Status Update | `mcp__linear__save_status_update` | `mcp__linear__get_status_updates` |
| Test results, mid-phase notes | Comment on the phase issue | `mcp__linear__save_comment` | `mcp__linear__list_comments` |
| Errors with the 3-strike protocol | Comment on the phase issue + `error` label on issue | `mcp__linear__save_comment`, `mcp__linear__save_issue` | `mcp__linear__list_comments`, `mcp__linear__list_issues` |
| Blocked phase | `blocker` label on issue | `mcp__linear__save_issue` | `mcp__linear__list_issues` |
| Active project pointer | `.planning/.active_linear` JSON | `set-active-linear.sh` | `resolve-active-linear.sh` |

## Why Phase = Issue (not Milestone)

Linear Milestones are project-level checkpoints with a target date and a derived `done` rollup from their issues. They have no native workflow state and accept no comments or labels. Mapping a phase to a milestone would require reinventing state tracking on top of milestones.

Issues, by contrast, give you state, parent/child hierarchy, comments, and labels — exactly the moving parts the original skill needed from `task_plan.md`.

If a phase grows beyond ~5 sub-tasks, the escape hatch is to keep the phase issue and add `parentId` sub-issues underneath. Don't promote phases to milestones unless you're managing a multi-month project that benefits from milestone target dates.

## Workflow State Mapping

Linear teams can rename their states ("Doing" instead of "In Progress", "Shipped" instead of "Done"). At init, call `mcp__linear__list_issue_statuses` for the chosen team and cache the actual names by their **type**:

```
type=backlog  → cached as states.backlog
type=unstarted → cached as states.todo
type=started  → cached as states.in_progress
type=completed → cached as states.done
type=canceled → cached as states.canceled
```

Always read from the cache (or re-fetch if missing) — never hardcode "In Progress".

## Label Conventions

Created at init via `mcp__linear__create_issue_label` if missing:

| Label | Applied to | Meaning |
|-------|-----------|---------|
| `phase` | Every phase issue | Filtering handle for `list_issues` |
| `error` | Phase issue with ≥1 error comment | The 3-strike protocol fired |
| `decision` | Phase issue with mid-phase decision comment | Helps reconstruct decision history |
| `blocker` | Phase issue stuck on external dependency | Surface for prioritization |

Comments themselves cannot carry labels in Linear — the convention is "comment body says what happened, parent issue's labels say what kind of thing happened."

## Status Update Cadence

`mcp__linear__save_status_update` is intended to be read by humans. Don't post one per tool call.

| When | Body | Health |
|------|------|--------|
| Session start (resume) | "Resuming at Phase N: <title>" | onTrack (or atRisk if errors logged) |
| Phase transition | "Completed Phase N. Starting Phase N+1." | onTrack |
| 3 errors hit in one phase | Use the 3-strike summary | offTrack |
| Session end | "Pausing at Phase N. Next: …" | (carry forward) |

Health mapping rule of thumb:
- 0 errors in current phase → `onTrack`
- 1–2 errors → `atRisk`
- 3+ errors or blocker label → `offTrack`

## Decisions: Document vs Comment

| Decision type | Goes in |
|---------------|---------|
| Architecture, technology choice, data model | Findings Document, "Technical Decisions" section |
| Mid-phase pivot ("changed approach because X") | Comment on the active phase issue + `decision` label on issue |

Document is searchable across the project's lifetime. Issue comments are anchored to the phase that made the call. Keep both.

## `.planning/.active_linear` Schema

```json
{
  "schema_version": 1,
  "project_id": "01H...",
  "project_url": "https://linear.app/<workspace>/project/<slug>-<short-id>",
  "project_name": "Backend Refactor",
  "team_id": "01H...",
  "team_key": "ENG",
  "document_id": "01H...",
  "states": {
    "backlog": "Backlog",
    "todo": "Todo",
    "in_progress": "In Progress",
    "done": "Done",
    "canceled": "Cancelled"
  },
  "phase_issues": [
    {"id": "ENG-101", "title": "Phase 1: Discovery", "state": "Done"},
    {"id": "ENG-102", "title": "Phase 2: Design",    "state": "In Progress"},
    {"id": "ENG-103", "title": "Phase 3: Implement", "state": "Todo"}
  ],
  "last_synced_at": "2026-05-07T14:22:31Z"
}
```

- **Refresh on**: init, `/sync`, `/status`, after every Status Update post.
- **Read by**: hooks (no network), `/status` (as fallback if MCP unavailable), `linear-catchup.sh`.
- **Trust level**: hint. Always re-fetch from Linear before branching on state. The hook output explicitly labels itself as "may be stale".

## Adapted Manus Principles

The original skill leaned on six Manus context-engineering principles. They still apply, retargeted at Linear:

### Principle 3 (was: Filesystem as External Memory) → **Linear as External Memory**

```
Context window  = RAM (volatile, limited)
Linear project  = Disk (persistent, shared, queryable)
```

Compression must be restorable: keep issue IDs and URLs even when dropping the full description from context. Never lose the pointer back to authoritative state.

### Principle 4 (was: Recitation via re-reading task_plan.md) → **Re-fetch before decisions**

After ~50 tool calls, the original goal drifts out of attention. Counter-measure: call `mcp__linear__get_project` and `mcp__linear__list_issues` (filter by project) right before any non-trivial branch. The fresh tool result lands at the end of context, where attention is highest.

### Principle 5 (was: Keep the wrong stuff in) → **Don't delete error comments**

The 3-strike error log is a feature, not a mess. Failed attempts with stack traces let the model implicitly update its beliefs and avoid repetition. Editing or deleting them — locally or in Linear — destroys learning signal.

### Principles 1, 2, 6 (KV-cache, mask-don't-remove, don't-get-few-shotted)

Unchanged. They're about the model's context window, not the storage backend. Keep prompt prefixes stable; vary phrasings on repetitive operations to avoid drift.

## Out of Scope

This skill uses Linear strictly as an external memory + status board. Out of scope:

- **Cycles** (sprint-style time-boxing) — the user can put issues into cycles manually.
- **Initiatives** (multi-project rollups) — for cross-task roadmapping.
- **Milestones** — see "Why Phase = Issue" above.
- **Customers / Customer Needs** — customer-request tracking.
- **Attachments** — Linear's file attachment surface.
- **Diffs / Diff Threads** — Linear's code-review surface.
- **Linear's `delegate` parameter on `save_issue`** — this skill stores plans in Linear; it does **not** delegate execution to Linear's built-in agent.
- **Localization variants** — only the English skill ships; the original's ar/de/es/zh/zht variants were dropped in this fork.
- **PowerShell scripts** — `.sh` only on Linux/macOS for v1.
- **IDE-specific mirrors** (`.codex`, `.cursor`, `.gemini`, `.kiro`, …) — the original's multi-IDE mirroring was dropped.

## Tool Inventory

Required Linear MCP tools (the skill assumes the `mcp__linear__` prefix; if your harness exposes Linear under a different prefix, the user's MCP server config is responsible for routing):

```
list_teams, get_team
save_project, get_project, list_projects
save_issue, get_issue, list_issues
list_issue_statuses
list_issue_labels, create_issue_label
save_document, get_document
save_status_update, get_status_updates
save_comment, list_comments
```

If `mcp__linear__list_teams` is not callable at init, the skill must surface a friendly prerequisite error and stop. See https://linear.app/docs/mcp.

## Design Notes

- **Idempotent init.** The `init-linear.sh` script and the `/plan` command both check `.planning/.active_linear` before creating anything. Re-running `/plan` on an already-initialized repo prints the existing project URL and asks whether the user wants to add new phases or start a new project.
- **Cache as hint, not source of truth.** The shell scripts only read and write `.planning/.active_linear`. They never call Linear. All authoritative state is fetched live by the model via MCP.
- **No SHA-256 attestation.** Linear data isn't a single hashable artifact; the original attestation flow doesn't translate. The injection surface is closed structurally instead — hooks never carry Linear bodies.
- **Schema versioning.** `.planning/.active_linear` carries `schema_version` so future migrations can be detected.
