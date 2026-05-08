Read codex_context.md before making changes.

Current working focus:
Section review/completion workflow inside the scope editor.

Highest-priority requirement:
Each section in the scope editor needs a lightweight “reviewed / complete” acknowledgment so the user can confirm they are done with that section for now. This is not validation and should not require fields. It should provide peace of mind without blocking editing or export.

Important constraint:
Do not destabilize the current working JobTread customer search/select, linked-customer hydration, verified read-only ownership behavior, Documents / Attachments section, pricing engine, persistence continuity fixes, or current PDF export improvements unless the task explicitly requires it.

Current app phase:
PDF export work has reached a reasonable stopping point for now. The next active phase is to add section-level completion/review workflow so users can clearly mark sections as reviewed and see which sections still need attention.

What is already true:
- SwiftUI iPad construction scope app exists
- Core section-based workflow exists
- Offline-first behavior remains important
- JobTread connectivity has been verified
- Scope naming has been separated from customer identity
- JobTread customer search/select creation path exists
- Live partial-name JobTread customer search works
- Selecting a JobTread customer creates a linked scope
- Linked-customer hydration works for some verified fields
- Documents / Attachments section exists and is functioning
- Signature and Site Diagram persistence have been strengthened enough to survive recent continuity tests
- PDF export currently includes only relevant scope content and has improved layout/thumbnail behavior

Known limitations / current truths:
- This section completion feature is not a validation system
- No fields should become required because of this feature
- Completion state should not block editing, saving, export, or future changes
- If a completed section is edited later, it must automatically return to a “Needs Review” state until the user re-confirms it

Current architectural direction:
- The app should remain fast and low-friction in the field
- Workflow reassurance is valuable, but it should not behave like form validation
- Section review/completion should be treated as lightweight persisted workflow state
- Section completion should be visible both:
  - inside the section
  - and from the section list/sidebar if possible
- Editing a previously completed section should automatically invalidate that completion state
- PDF/export behavior should not depend on section completion state in this phase

Immediate implementation direction:
- Add section-level completion/review state
- Add a lightweight in-section control such as:
  - Mark Section Complete
  - Completed / Needs Review state
- Show section completion state in the section list/sidebar
- Preserve the ability to freely edit completed sections
- Automatically reset a section from Completed to Needs Review when its content changes
- Do not introduce required-field validation or export gating

Most relevant near-term domains to build:
- section completion state model
- section completion UI control
- sidebar/list completion indicators
- automatic completion invalidation on section edits
- persisted workflow-state handling for sections

Current priorities:
1. Add lightweight section completion/review acknowledgment
2. Show completion state clearly in the editor and section list
3. Automatically reset completion when a section changes
4. Preserve free editing and no-required-fields behavior
5. Avoid coupling completion state to export or validation

Editing rules:
- Follow READ → PLAN → EDIT
- Make surgical edits
- Do not rewrite large files unnecessarily
- Preserve working service and model boundaries
- Explain what files changed and why
- Prefer incremental, production-safe changes over broad refactors
- Keep business logic out of low-level rendering code
- This phase is workflow-state UX, not validation or export logic
