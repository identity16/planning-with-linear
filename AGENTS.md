# AGENTS.md — `planning-with-linear` agent reference

This file is the canonical reference for agents working in this fork. The original `planning-with-files` AGENTS.md described OthmanAdi's release process, version-bump scope, and ClawHub upload flow. None of that applies here — this fork is a single-skill, English-only, Claude-Code-only, MIT-licensed project.

---

## Repository scope

- One skill: `skills/planning-with-linear/`.
- Four slash commands: `commands/{plan,start,status,sync}.md`.
- Plugin metadata: `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`.
- Linux/macOS bash scripts only (no PowerShell, no IDE mirrors).
- No localization variants.

If you find yourself bumping more than three files for a version change, you are doing something the fork was designed to avoid. Stop and reconsider.

---

## Commit conventions

- **Format**: Conventional Commits — `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`.
- **One commit per logical change.** Squash work-in-progress before pushing.
- **No `--no-verify`.** If a hook fails, fix the underlying issue.
- **No force pushes** to shared branches without an explicit reason.

The original repo banned `Co-Authored-By:` trailers. This fork does not — Claude Code commits trailing `https://claude.ai/code/session_…` are fine; collaborator trailers are at the contributor's discretion.

---

## Linear MCP assumption

The skill assumes Linear MCP tools are exposed as `mcp__linear__*`. If your MCP server registers Linear under a different prefix, the user's MCP server config controls routing — do not hardcode prefixes anywhere except `SKILL.md`'s `allowed-tools` field and the example MCP call names in `reference.md` / `examples.md`.

If you change the assumed prefix, update:

1. `skills/planning-with-linear/SKILL.md` — `allowed-tools` frontmatter
2. `skills/planning-with-linear/reference.md` — Tool Inventory section, mapping table
3. `skills/planning-with-linear/examples.md` — every code block
4. `commands/{plan,start,status,sync}.md` — every reference

---

## Hook behavior contract

Hooks **must not** carry Linear content (issue bodies, comments, status update text, document content) into the model context. They are restricted to:

- Reading `.planning/.active_linear` (local JSON cache).
- Emitting project IDs, URLs, label names, cached phase state names, and short reminders.
- Calling `git log` / `git status` (read-only) for catchup detection.

This invariant is what removes the need for SHA-256 attestation. Breaking it reintroduces the injection surface the original skill spent v2.21.0–v2.37.0 hardening.

---

## File-edit boundaries

- `.planning/.active_linear` is **written only** by `set-active-linear.sh`. The model constructs the JSON payload from MCP responses and passes it as the script's argument.
- Templates under `skills/planning-with-linear/templates/` are **markdown bodies** the model renders into MCP `save_*` calls. They are not files written to disk in user projects.
- `SKILL.md` frontmatter `version` and `.claude-plugin/plugin.json`'s `version` must match. There are only two places to update for a release.

---

## CHANGELOG format

```
## [X.Y.Z] - YYYY-MM-DD

### Added / Changed / Fixed / Removed / Security
- One sentence per change. Sachlich, no em-dashes.
```

Historical entries from the original `planning-with-files` repo are preserved below the v1.0.0 fork entry — do not edit them.

---

## What this fork explicitly does NOT do

- Mirror to other IDEs.
- Ship localization variants.
- Provide PowerShell scripts.
- Use Linear Cycles, Initiatives, Customers, Customer Needs, Attachments, Diffs, or `save_issue.delegate`.
- Auto-bump version across multiple SKILL.md variants (there's only one).
- Upload to ClawHub or any third-party marketplace.

---

## Quick reference: what NOT to do

- Don't inject Linear content via hooks. Hooks read `.planning/.active_linear` only.
- Don't reopen Done issues. Add new ones in the same project.
- Don't post per-tool-call status updates. Cadence: session start, phase transition, session end.
- Don't put error details in status updates. Errors go in phase issue comments.
- Don't trust the `.planning/.active_linear` cache for control flow. Re-fetch with `get_project` before deciding.
- Don't recreate the localization or IDE-mirror surfaces removed in the v1.0.0 fork.
