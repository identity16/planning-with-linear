<!--
  Template: Project Status Update body.
  Consumed by: mcp__linear__save_status_update (body field).
  Also pass: health = onTrack | atRisk | offTrack.

  Cadence: session start, phase transitions, session end. Not per tool call.
  Health rule of thumb:
    0 errors in current phase  → onTrack
    1–2 errors                 → atRisk
    3+ errors or blocker label → offTrack
-->

## What changed

{{ONE_OR_TWO_SENTENCES}}

## Where we are

- Active phase: {{ACTIVE_PHASE_ID_AND_TITLE}}
- Done: {{DONE_COUNT}} / {{TOTAL_COUNT}}
- Errors logged in this phase: {{ERROR_COUNT}}

## Next

{{NEXT_STEP_ONE_LINE}}
