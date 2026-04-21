Read codex_context.md before making changes.

Project:
Production iPad SwiftUI app: Construction Scope App.

Current phase:
Field-beta stabilization and workflow hardening. Prioritize reliable real-world data entry, persistence, and PDF/export behavior over broad refactors.

Core architecture rules:
- SwiftUI + async/await
- Keep business logic out of Views
- Use clear boundaries:
  - Models = data structures / normalization helpers
  - Views = UI only
  - ViewModels / Services = stateful behavior, integration, persistence helpers
- Make surgical, incremental edits
- Do not rewrite large files unnecessarily
- Preserve working integrations and workflows unless the task explicitly requires change

Non-negotiables:
- Offline-first behavior
- Autosave workflow
- PDF export must remain flattened and production-order friendly
- JobTread is the source of truth for customer records
- Do not create duplicate customers
- Preserve same-device beta continuity as much as possible
- Avoid risky persistence-shape changes unless absolutely necessary

Current stable/working areas that must not be broken:
- JobTread customer search/select and linked-customer hydration
- Read-only JobTread-owned customer/location behavior
- Scope Title editing behavior (spaces now work there)
- Enclosure multi-select behavior and export pruning
- Existing Conditions nested selection behavior
- Existing Conditions checklist photo workflow
- File-backed checklist photo persistence
- Current PDF export/render/share pipeline
- Debug inspector
- Pricing/proposal foundation

Important UX/data behavior already established:
- User-facing editable text fields should not be aggressively normalized on every keystroke
- Raw editable text should be preserved during typing
- Normalization should happen only at appropriate save/display/output boundaries
- For branch-driven sections, hidden inactive values may be temporarily preserved during editing
- Hidden inactive values must be excluded/pruned from export/output
- Prefer progressive disclosure for dependent controls

Current active task:
Audit text entry behavior across the app and fix fields where users cannot type spaces during normal editing.

Required behavior:
- In virtually every general-purpose text field, especially notes-style fields, users must be able to enter normal spaces and type multi-word text
- This should apply across sections, not just one field
- Do NOT change numeric-only or constrained-entry fields that should remain restricted, such as:
  - phone number fields
  - email fields
  - measurement / numeric fields
  - any field intentionally formatted as numeric-only or tokenized input
- The fix should be systematic and architecture-aware, not a one-off patch to a single field

Likely root cause pattern:
- Some text fields are probably still using normalized/computed bindings or setters that trim/collapse whitespace on every keystroke
- The previous Scope Title bug was fixed by separating raw editable state from normalized display/output state
- Similar patterns may still exist elsewhere in the app

Implementation guidance:
- Audit all user-editable text fields and their bindings/setters/update paths
- Identify every field where whitespace is being stripped during live entry
- Apply the same safe pattern used for Scope Title where appropriate:
  - raw editable value during typing
  - normalization only at save/display/output boundaries
- Keep intentionally constrained fields constrained
- Prefer shared helper patterns over scattered ad hoc fixes, but do not over-refactor

Editing rules:
- Follow READ → PLAN → EDIT
- Explain what files changed and why
- Keep diffs scoped
- Do not refactor unrelated app areas
- This phase is production-hardening first, not feature-first
