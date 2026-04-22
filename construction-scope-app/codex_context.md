Read codex_context.md before making changes.

Project:
Production iPad SwiftUI app: Construction Scope App.

Current phase:
Field-beta stabilization and workflow hardening. Prioritize reliable real-world data entry, persistence, and PDF/export behavior over broad refactors.

Core rules:
- SwiftUI + async/await
- Keep business logic out of Views
- Make surgical, incremental edits
- Do not rewrite large files unnecessarily
- Preserve working integrations and workflows unless the task explicitly requires change
- Offline-first
- Autosave
- Flattened PDF export
- JobTread is the source of truth for customers
- Avoid risky persistence-shape changes unless absolutely necessary

Stable areas that must not be broken:
- JobTread customer search/select and linked hydration
- Scope Title text-entry fix
- Multi-word text-entry fixes across general human text fields
- Project Type multi-select behavior and scope card display
- Existing Conditions nested selection behavior
- Existing Conditions checklist photo workflow and file-backed persistence
- Structural System branching workflow
- Current PDF export/render/share pipeline
- Debug inspector
- Pricing/proposal foundation

Established UX/data patterns:
- User-facing text fields preserve raw editable text during typing
- Normalize only at save/display/output boundaries
- Branch-driven sections use progressive disclosure
- Hidden inactive values may be preserved during editing
- Hidden inactive values must be excluded/pruned from export/output

Current active task:
Adjust section naming and options so Enclosure becomes Screen Enclosure, Windows & Glass becomes Sunroom, remove outdated enclosure-type options, and add a dedicated Screen Enclosure Notes field.

Required behavior:
- Rename the visible section title `Enclosure` to `Screen Enclosure`
- Rename the visible section title `Windows & Glass` to `Sunroom`
- In Enclosure Type, remove:
  - Vinyl Window Enclosure
  - Glass Sunroom
- Preserve the remaining Enclosure Type options unless code structure requires otherwise
- Add a dedicated `Screen Enclosure Notes` text field
- This notes field should:
  - be a normal human text-entry field
  - allow spaces / multi-word text
  - autosave and persist
  - be clearly associated with Screen Enclosure
- Prefer a safe UI/data change, not a broad internal architectural rename, unless absolutely required

Implementation guidance:
- Audit the full Enclosure / Windows & Glass flow before changing code:
  - visible section labels
  - Enclosure Type option source
  - model storage if relevant
  - editor UI
  - export/proposal/PDF labels/output if these section names or values appear there
- Prefer the smallest production-safe path
- Reuse existing notes/text-entry patterns
- Keep Sort/sidebar/list behavior untouched
- Avoid broad persistence risk if possible

Editing rules:
- Follow READ → PLAN → EDIT
- Explain what files changed and why
- Keep diffs scoped
- Do not refactor unrelated app areas
- This phase is production-hardening first, not feature-first
