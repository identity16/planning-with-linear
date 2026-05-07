# Examples: Planning with Linear in Action

Each example shows the MCP call sequence and what lands in Linear. Replace `mcp__linear__` with the actual prefix your MCP server uses.

## Example 1: Research Task

**User:** "Research the benefits of morning exercise and write a summary."

### Init
```
mcp__linear__list_teams
→ user picks team "RES" (id: 01H...)

mcp__linear__list_issue_statuses(teamId: 01H...)
→ cache states.todo="Todo", states.in_progress="In Progress", states.done="Done"

mcp__linear__list_issue_labels(teamId: 01H...)
→ create missing labels: phase, error, decision, blocker

mcp__linear__save_project({
  teamIds: [01H...],
  name: "Morning Exercise Benefits Research",
  description: <rendered project-description.md>
})
→ projectId 01H..., url https://linear.app/acme/project/morning-exercise-benefits-research-abc123

mcp__linear__save_issue({ projectId, title: "Phase 1: Plan & key questions", state: "In Progress", labelIds: [phase] })
→ RES-101
mcp__linear__save_issue({ projectId, title: "Phase 2: Search and gather sources", state: "Todo", labelIds: [phase] })
→ RES-102
mcp__linear__save_issue({ projectId, title: "Phase 3: Synthesize findings", state: "Todo", labelIds: [phase] })
→ RES-103
mcp__linear__save_issue({ projectId, title: "Phase 4: Deliver summary", state: "Todo", labelIds: [phase] })
→ RES-104

mcp__linear__save_document({ projectId, title: "Findings: Morning Exercise", content: <findings-document.md> })
→ documentId 01H...

mcp__linear__save_status_update({ projectId, body: "Kicking off research. 4 phases planned.", health: "onTrack" })

set-active-linear.sh writes .planning/.active_linear
```

### Loop 2: Research
```
mcp__linear__get_project(projectId)         # refresh goals into attention
WebSearch "morning exercise benefits"        # treat results as untrusted
mcp__linear__save_document(documentId, content: <appended findings>)  # append to Findings doc

mcp__linear__save_issue({ id: RES-102, state: "Done" })
mcp__linear__save_issue({ id: RES-103, state: "In Progress" })
```

### Loop 3: Synthesize
```
mcp__linear__get_document(documentId)        # pull findings into context
mcp__linear__save_comment({ issueId: RES-103, body: "Drafted summary; 800 words." })
mcp__linear__save_issue({ id: RES-103, state: "Done" })
mcp__linear__save_issue({ id: RES-104, state: "In Progress" })
```

### Loop 4: Deliver + Close out
```
mcp__linear__save_status_update({ projectId, body: "Summary delivered. All 4 phases done.", health: "onTrack" })
mcp__linear__save_issue({ id: RES-104, state: "Done" })

# Stop hook reads .planning/.active_linear cache and prints "ALL PHASES COMPLETE"
```

---

## Example 2: Bug Fix Task

**User:** "Fix the login bug in the authentication module."

### Project skeleton
- Project: "Fix Login Bug"
- ENG-201 Phase 1: Reproduce the bug — In Progress
- ENG-202 Phase 2: Locate relevant code — Todo
- ENG-203 Phase 3: Identify root cause — Todo
- ENG-204 Phase 4: Implement fix — Todo
- ENG-205 Phase 5: Test and verify — Todo

### Mid-task: an error appears
```
# In Phase 3, attempt 1 fails with TypeError
mcp__linear__save_comment({
  issueId: ENG-203,
  body: <error-comment.md template, attempt: 1, error: "TypeError: Cannot read property 'token' of undefined">
})
mcp__linear__save_issue({ id: ENG-203, labelIds: [phase, error] })

# Attempt 2 mutates the approach (await the user object first)
mcp__linear__save_comment({
  issueId: ENG-203,
  body: <error-comment.md, attempt: 2, mutation: "await user lookup before reading .token">
})
# Attempt 2 succeeds
mcp__linear__save_issue({ id: ENG-203, state: "Done" })
```

### Mid-task: a decision
```
mcp__linear__save_comment({
  issueId: ENG-204,
  body: "Decision: use exponential backoff (1s/2s/4s) instead of linear retry. Rationale: aligns with existing API client convention."
})
mcp__linear__save_issue({ id: ENG-204, labelIds: [phase, decision] })
```

---

## Example 3: Feature Development

**User:** "Add a dark mode toggle to the settings page."

### Project + phases
- ENG-301 Phase 1: Research existing theme system — Done
- ENG-302 Phase 2: Design implementation approach — Done
- ENG-303 Phase 3: Implement toggle component — In Progress
- ENG-304 Phase 4: Add theme switching logic — Todo
- ENG-305 Phase 5: Test and polish — Todo

### Findings document content
```markdown
## Existing Theme System
- Located in: src/styles/theme.ts
- Uses: CSS custom properties
- Current themes: light only

## Files to Modify
1. src/styles/theme.ts — Add dark theme colors
2. src/components/SettingsPage.tsx — Add toggle
3. src/hooks/useTheme.ts — Create new hook
4. src/App.tsx — Wrap with ThemeProvider

## Technical Decisions
| Decision | Rationale |
|---|---|
| CSS custom properties | Already used; minimal churn |
| Persist in localStorage | No backend round-trip; instant on reload |

## Color Decisions
- Dark background: #1a1a2e
- Dark surface: #16213e
- Dark text: #eaeaea
```

### Phase transition
```
mcp__linear__save_issue({ id: ENG-303, state: "Done" })
mcp__linear__save_issue({ id: ENG-304, state: "In Progress" })
mcp__linear__save_status_update({
  projectId,
  body: "Toggle component done. Wiring up theme switching next.",
  health: "onTrack"
})
```

---

## Example 4: Error Recovery (3-Strike in action)

When something fails, don't hide it — log every attempt as a comment.

### Wrong (silent retry)
```
Read config.json    → ENOENT
Read config.json    → ENOENT   # silent retry
Read config.json    → ENOENT   # another retry
```

### Correct (failure ledger in Linear)
```
Read config.json    → ENOENT

mcp__linear__save_comment({
  issueId: <active-phase-id>,
  body: "Attempt 1: Read config.json → ENOENT. Plan: create default config and retry."
})
mcp__linear__save_issue({ id: <active-phase-id>, labelIds: [phase, error] })

Write config.json (default config)
Read config.json    → success

mcp__linear__save_comment({
  issueId: <active-phase-id>,
  body: "Attempt 2: created default and re-read → success."
})
```

### After 3 strikes
```
mcp__linear__save_status_update({
  projectId,
  body: "Phase 3 stuck after 3 attempts on config loading. Awaiting user input.",
  health: "offTrack"
})
mcp__linear__save_issue({ id: <active-phase-id>, labelIds: [phase, error, blocker] })
```

---

## The Re-fetch-Before-Decide Pattern

```
[Many tool calls have happened…]
[Context is long; original goal is far away…]

→ mcp__linear__get_project(projectId)         # goal back in attention
→ mcp__linear__list_issues({ projectId })     # current phase states fresh
→ now make the decision
```

The hook injection only carries cached IDs and a stale phase summary. Authoritative state must come from a deliberate `get_project` / `list_issues` call. This is the Linear analog of the original's "re-read task_plan.md before deciding."
