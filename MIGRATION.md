# Migration: `planning-with-files` → `planning-with-linear`

This guide is for users of [OthmanAdi/planning-with-files](https://github.com/OthmanAdi/planning-with-files) v2.x who want to switch to this Linear-backed fork.

## TL;DR

The Manus pattern is unchanged. The storage backend moves from local markdown to Linear:

| Before (`planning-with-files`) | After (`planning-with-linear`) |
|---|---|
| `task_plan.md` in your repo | Linear **Project** + phase **Issues** |
| `findings.md` in your repo | Linear **Document** linked to the project |
| `progress.md` in your repo | Linear **Status Updates** + Issue **Comments** |
| Phase status checkbox | Issue workflow state (Todo / In Progress / Done) |
| Errors logged in markdown table | Comments on phase issue + `error` label |
| `.planning/.active_plan` | `.planning/.active_linear` (cached project ID) |
| `/plan-attest` (SHA-256 lock) | Removed — different threat model |

You keep the 3-strike error protocol, the 2-action rule, the 5-question reboot test, and the read-before-decide pattern. They now target Linear surfaces instead of markdown files.

## Prerequisites

- A Linear MCP server registered with your harness, exposing `mcp__linear__*` tools. See [linear.app/docs/mcp](https://linear.app/docs/mcp).
- Permission to create projects, issues, documents, status updates in at least one Linear team.

## Migration steps

### 1. Install the new skill

```
/plugin marketplace add identity16/planning-with-linear
/plugin install planning-with-linear@planning-with-linear
```

### 2. Decide what to do with in-flight `task_plan.md` files

For each repo with active planning files:

- **Finish in markdown, then switch.** Easiest. Complete the active task using `planning-with-files`, then start the next task with `/plan` (Linear-backed).
- **Port now.** Run `/plan` in the repo, pick a team, give the same task name. The skill will create a fresh Project + phase Issues. Manually copy the relevant content from `task_plan.md` / `findings.md` / `progress.md` into the matching Linear surfaces:
  - Goal → Project description
  - Each phase heading → one Issue (set state to match the markdown checkbox: `[ ]` → Todo, `[x]` → Done, the active one → In Progress)
  - Findings sections → Findings Document
  - Errors table → comments on the relevant phase issue, with the `error` label

### 3. Clean up old artifacts

After porting (or when no longer needed):

```
rm -rf .planning/ task_plan.md findings.md progress.md .plan-attestation
```

`.planning/.active_linear` lives in the same `.planning/` directory in the new skill, so don't `rm` the directory if you've already initialized a Linear plan.

### 4. Slash commands stay the same

`/plan`, `/start`, `/status` keep their names. New addition: `/sync` (refreshes `.planning/.active_linear` from Linear). Removed: `/plan-attest`.

## Conceptual changes

### Read vs. write paths

In `planning-with-files`, hooks read `task_plan.md` on every prompt and tool call and inject up to 50 lines into the model context. That made attestation necessary — the file's bytes flowed straight into the prompt, so a malicious local edit was a prompt-injection vector.

In `planning-with-linear`, hooks **never inject Linear content**. They only read `.planning/.active_linear` (a small, locally-controlled JSON cache) and emit the project URL + a "re-fetch with `get_project` for fresh state" reminder. Linear bodies arrive in context only via deliberate `mcp__linear__*` tool calls the model can label as untrusted. SHA-256 attestation is therefore unnecessary and was dropped.

### Phase = Issue (not Milestone)

Linear has Milestones, but they have no native workflow state and accept no comments or labels. The original skill's pending/in_progress/complete carry over cleanly to Issue states (Todo/In Progress/Done) — Issues, not Milestones, are the natural fit. See `skills/planning-with-linear/reference.md` for the rationale.

### Status Update cadence

`progress.md` was append-only and unbounded. Linear Status Updates are visible to stakeholders in the project view — don't post one per tool call. Recommended cadence: session start, phase transitions, session end. Fine-grained logs go in issue comments.

The new `health` field (`onTrack` / `atRisk` / `offTrack`) maps to error count in the active phase: 0 → onTrack, 1–2 → atRisk, 3+ or blocker → offTrack.

### Decisions go in two places

Long-form, durable technical decisions → Findings Document, "Technical Decisions" section.

Mid-phase tactical decisions ("we changed approach because X") → comment on the phase issue + `decision` label. Anchored to the phase that made the call.

## What's removed

- The 5 localization variants (`-ar`, `-de`, `-es`, `-zh`, `-zht`).
- The 11+ IDE mirror directories (`.codex`, `.cursor`, `.gemini`, …). This skill targets Claude Code only.
- PowerShell scripts. Linux/macOS bash only.
- `/plan-attest`, `attest-plan.sh`/`.ps1`, the SHA-256 attestation flow.
- `session-catchup.py` (438 lines of session JSONL parsing). Replaced by `linear-catchup.sh` (~50 lines comparing `last_synced_at` against `git log`).
- The `analytics` template variant. The default templates cover analytics use cases via the Findings Document.

## Questions

Open an issue at https://github.com/identity16/planning-with-linear/issues.
