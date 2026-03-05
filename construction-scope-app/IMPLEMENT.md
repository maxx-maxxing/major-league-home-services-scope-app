# IMPLEMENT.md
# Execution Runbook for Codex

Follow these rules while implementing.

## Scope Control
- Do not expand scope beyond the current milestone.
- If a missing requirement is discovered, record it in DOCUMENTATION.md and propose a follow-up milestone in PLANS.md.

## Repo Hygiene
- Keep diffs small and reviewable.
- Use clear file names and consistent folder structure.
- Prefer composing reusable UI components (cards, rows).

## Validation After Each Milestone
After each milestone:
- Build the app successfully (no warnings preferred).
- Run a smoke test path:
  - New Scope
  - Edit Project Info
  - Edit Enclosure / Windows / Attachments
  - Preview and Export PDF (stub acceptable until Milestone 4)
- Fix failures immediately before moving on.

## UI Rules
- Follow UI_SYSTEM.md strictly.
- Use system components and semantic fonts.
- Keep tap targets >= 44x44.
- Prefer pickers/toggles over typing.
- Notes use TextEditor to support Scribble.

## Persistence Rules
- Offline-first: no network requirement.
- Autosave with debounced writes.
- Template is read-only; each job is a new instance.

## PDF Rules
- Follow PDF_EXPORT.md.
- PDF must be flattened by default.
- Include signature image and signed date.
