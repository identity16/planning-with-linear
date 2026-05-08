<!--
  Template: Phase Issue description body.
  Consumed by: mcp__linear__save_issue (description field).
  The issue itself carries: title="Phase N: <short title>", labels=["phase"], state="Todo" (or "In Progress" for the first phase).
-->

## Goal

{{PHASE_GOAL_ONE_SENTENCE}}

## Definition of Done

- [ ] {{DOD_ITEM_1}}
- [ ] {{DOD_ITEM_2}}
- [ ] {{DOD_ITEM_3}}

## Inputs

- Project: {{PROJECT_URL}}
- Findings document: {{FINDINGS_DOCUMENT_URL}}

Dependencies on other phases live as Linear issue relations (`blockedBy` / `blocks`), not in this body. Fetch them with `get_issue({ id, includeRelations: true })`. Use the `blocker` label only for *external* blockers (vendor, missing access, unanswered question) that aren't another issue in this plan.

## Notes

Mid-phase work logs (test results, decisions, errors) belong as comments on this issue, not in the project description. When the phase finishes, transition state to `Done` and let any phase that was `blockedBy` this one move from `Backlog` to `Todo`.
