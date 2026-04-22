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
- Section-scoped Measurements workflow
- Current PDF export/render/share pipeline
- Debug inspector
- Pricing/proposal foundation

Established UX/data patterns:
- User-facing text fields preserve raw editable text during typing
- Normalize only at save/display/output boundaries
- Branch-driven sections use progressive disclosure
- Hidden inactive values may be preserved during editing
- Hidden inactive values must be excluded/pruned from export/output
- The app should feel like a first-party Apple productivity app: calm, obvious, low ambiguity

Current active task:
Improve text-field clarity so values remain understandable after users type into fields.

Required behavior:
- Most text-entry fields should no longer rely on placeholder text alone to communicate meaning
- Once a field has a value, the UI must still clearly indicate what that value represents
- Prefer persistent visible labels for fields where placeholder-only behavior currently creates ambiguity
- This is especially important for stacked fields such as:
  - widths
  - heights
  - projections
  - counts
  - measurement values
  - write-in fields
  - other repeated form fields where multiple similar inputs appear together

Implementation guidance:
- Audit text-entry fields across the app
- Convert placeholder-only fields into persistently labeled fields where appropriate
- Prefer a shared labeled-field pattern rather than inconsistent one-off fixes
- Keep the UI clean and uncluttered
- Do not duplicate labels unnecessarily where the surrounding card/section title already makes the field’s meaning obvious
- Good default rule:
  - stacked/shared fields inside a card should each have their own visible label
  - single obvious standalone note fields do not need redundant duplicate labels if the card title already communicates the meaning clearly
- Preserve existing helper text below fields where it adds value

Editing rules:
- Follow READ → PLAN → EDIT
- Explain what files changed and why
- Keep diffs scoped
- Do not refactor unrelated app areas
- This phase is production-hardening first, not feature-first
