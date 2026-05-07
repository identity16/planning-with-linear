<!--
  Template: Linear Project description body.
  Consumed by: mcp__linear__save_project (description field).
  Render this markdown into a string and pass as `description`.
-->

# {{TASK_NAME}}

## Goal

{{ONE_SENTENCE_GOAL}}

## Phases

{{#each PHASES}}
- **Phase {{n}}: {{title}}** — {{summary}}
{{/each}}

## Key Questions

{{#each QUESTIONS}}
- {{this}}
{{/each}}

## Linked Resources

- Findings document: {{FINDINGS_DOCUMENT_URL}}
- Repository (if any): {{REPO_URL}}

## Notes

This project is managed by the `planning-with-linear` skill. Phase issues carry the `phase` label. Errors are logged as comments on the active phase issue with the `error` label. Status Updates summarize progress for stakeholders; fine-grained logs live in issue comments.
