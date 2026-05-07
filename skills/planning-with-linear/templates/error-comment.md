<!--
  Template: Error comment on a phase issue.
  Consumed by: mcp__linear__save_comment (body field).
  After posting, also apply the `error` label to the parent issue (mcp__linear__save_issue with labelIds).

  3-Strike Protocol:
    Attempt 1: Diagnose & fix.
    Attempt 2: Mutate the approach. Never repeat the failing action verbatim.
    Attempt 3: Broader rethink; question assumptions; consider revising the phase plan.
    After 3 failures: post a Status Update with health=offTrack, add `blocker` label, escalate.
-->

### Error — Attempt {{ATTEMPT_NUMBER}}

**Where:** {{TOOL_OR_FILE_OR_COMMAND}}

**Symptom:**
```
{{ERROR_MESSAGE_OR_STACK_TRACE}}
```

**Diagnosis:**
{{ROOT_CAUSE_HYPOTHESIS}}

**Mutation for next attempt:**
{{WHAT_WILL_CHANGE_NEXT_TIME}}

**Outcome:**
{{FILLED_AFTER_NEXT_ATTEMPT — "fixed" / "still failing" / "escalated"}}
