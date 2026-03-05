# AGENTS.md

## Project
**iPad Construction Scope & Production Order App**  
Primary platform: **iPadOS**  
Secondary platforms: **macOS**, **iOS**

This app captures construction job scopes in the field and exports a professional **flattened PDF** that functions as a **production order**.

## How to Work in This Repo
- Treat `schema.json` as the **authoritative** source of truth for fields and enums.
- Implement UI strictly from `UI_SYSTEM.md` design rules.
- Implement PDF output strictly from `PDF_EXPORT.md` rules.
- If you need to add a field, update **schema.json first**, then update docs.

## Non‑Negotiables
- **SwiftUI-first** UI. No web UI. No form-builder UI frameworks.
- **NavigationSplitView** on iPad (sidebar sections + detail editor).
- **Offline-first**: app must function fully without internet.
- **Template immutability**: template is view-only; jobs are created as copies.
- **Apple Pencil Scribble** must work in all long-text fields (use TextEditor).
- **Signature + Diagram** use PencilKit.
- **PDF export** must be **flattened** by default (not editable fields).

## UI Quality Bar
The app must resemble a **first‑party Apple app** (Files / Notes / Reminders):
- System typography (semantic fonts)
- System materials and grouped backgrounds
- SF Symbols only
- Excellent spacing, minimal visual noise
- Works perfectly in Light/Dark mode and Dynamic Type
- Minimum tap target: 44x44 points

## Implementation Guardrails
- Prefer `Picker`, `Toggle`, `SegmentedControl` for selections.
- Avoid fake checkboxes.
- Use progressive disclosure: hide dependent fields until enabled.
- Autosave after edits; no “Save” button required.

## Deliverables
- A working SwiftUI app with:
  - section-based data entry
  - autosave
  - PDF preview + export flow (ShareLink / Save to Files)
  - optional photo attachments and a sketch page
  - acceptance checks from `ACCEPTANCE.md`
## Planning + Execution Docs (Use These)
This repo includes planning/runbook docs to keep long tasks reliable:

- `PLANS.md` = milestone-by-milestone execution plan (source of truth for implementation order)
- `IMPLEMENT.md` = runbook (how to work: keep diffs scoped, run validation, update docs)
- `DOCUMENTATION.md` = living status log (what changed, decisions, how to run/demo)

When a request spans multiple files or more than ~30 minutes of work:
1) Update `PLANS.md` first (propose milestones)
2) Implement milestone-by-milestone following `IMPLEMENT.md`
3) Update `DOCUMENTATION.md` as you go
