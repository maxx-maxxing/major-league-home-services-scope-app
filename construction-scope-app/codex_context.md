Read codex_context.md before making changes.

Current working focus:
Production-hardening for TestFlight field beta distribution, while continuing small, surgical workflow improvements that directly support real field use.

Current active feature task:
Restructure the Structural System section so it follows the client-approved decision-tree workflow rather than the current shallow Frame Material / Roof System form.

Required Structural System behavior:

Structural System:
- The current Structure section is too shallow and does not reflect the real estimator workflow
- Replace the current Structure / Roof + Finish flow with a top-level Structural System workflow
- Structural System should be a single primary selection that drives conditional UI
- Initial Structural System options should be:
  - Insulated Aluminum Patio Cover
  - Pergola
  - None
  - Other
- If Other is selected, a clearly labeled required text field should appear

Insulated Aluminum Patio Cover:
- If Structural System = Insulated Aluminum Patio Cover, show fields for:
  - Width
  - Projection
  - Number of Posts
  - Roof Type
- Width should reflect the client note that this is typically handled in 4-foot increments
- Projection should reflect the client note that this is typically handled in 2-foot increments
- Number of Posts should be captured as a field; client notes suggest:
  - 20 feet or less = 2 posts
  - 20+ feet = 3 or more posts
- Roof Type options should include:
  - Shingles
  - Roll Roofing

Pergola:
- If Structural System = Pergola, show a Pergola Type selector
- Pergola Type options should be:
  - Motorized Louvered Pergola
  - Manually Retractable Louvered Pergola
  - Cedar Pergola
  - Alumawood Pergola

Motorized Louvered Pergola:
- If Pergola Type = Motorized Louvered Pergola, show:
  - Width
  - Length
  - Height
  - Optional notes/help text if needed for client guidance
- Preserve the client note that max-per-unit constraints may apply, but keep first-pass implementation practical and not overengineered

Manually Retractable Louvered Pergola:
- If Pergola Type = Manually Retractable Louvered Pergola, show:
  - Width
  - Length
  - Height
  - Optional notes
- Treat this similarly to the Motorized Louvered branch for the first implementation pass unless the client later specifies more detailed branching

Cedar Pergola:
- If Pergola Type = Cedar Pergola, show:
  - Post Size
  - Beam Size
  - Rafter Size
  - Lattice
  - Hardware
  - Finish
  - Product Code
- Cedar Pergola field behavior:
  - Post Size options:
    - 4x4
    - 6x6
    - Other
  - If Post Size = Other, show a write-in field
  - Beam Size options:
    - 2x8
    - Other
  - If Beam Size = Other, show a write-in field
  - Rafter Size options:
    - 2x6
    - Other
  - If Rafter Size = Other, show a write-in field
  - Lattice options:
    - 2x2
    - 2x4
  - Hardware options:
    - Galvanized
    - Ornamental
  - Finish options:
    - Stained
    - Painted
  - Product Code should be a write-in field

Alumawood Pergola:
- If Pergola Type = Alumawood Pergola, show:
  - Mount Type
  - Layout / Dimensions
  - Attachment Type
  - Color
  - Privacy Wall
  - Dimensions / Notes as needed
- Alumawood Pergola field behavior:
  - Mount Type options:
    - Freestanding
    - Attached
  - Layout should support Width x Length x Height
  - Attachment Type options:
    - Isolated Footing
    - Surface Attachment
  - Color options:
    - White
    - Desert Sand
    - Mojave
    - Tan
    - Latte
    - Adobe
    - Spanish Brown
    - Graphite
  - Privacy Wall should be yes/no

Structural Notes:
- Preserve a Structural Notes area
- It should remain a long-form text entry field appropriate for Scribble/TextEditor use

General Structural System UX expectations:
- This section should behave like a decision tree with progressive disclosure
- Do not show irrelevant child fields until the parent selection requires them
- Keep the layout clean, obvious, and field-friendly
- Avoid overengineering calculations in this pass; capture the needed estimator inputs first
- Use sensible first-pass controls:
  - Pickers / Menus / segmented controls where appropriate
  - write-in fields only where clearly required
- If an Other option is selected anywhere, the corresponding write-in field should be clearly labeled

Hidden/dependent state behavior:
- If a parent option is changed so a child branch becomes inactive, those hidden child values may be temporarily preserved during editing
- Hidden inactive values must not be treated as active output data
- On PDF export / proposal output, inactive hidden values must be pruned so they do not appear in exported output and do not remain as lingering hidden state afterward
- This hidden-state behavior should remain consistent with the recent Enclosure and Existing Conditions patterns where practical

Important constraint:
Do not destabilize the current working JobTread customer search/select, linked-customer hydration, verified read-only ownership behavior, Documents / Attachments section, pricing engine, returned pricing normalization/validation path, debug inspector, PDF export pipeline, recent Scope Title text-entry fix, Enclosure multi-select work, Existing Conditions nested selection work, or Existing Conditions checklist photo workflow unless the task explicitly requires it.

Current app phase:
The app is advanced enough for real field beta use, but production hardening is still in progress. Current work should prioritize reliability in Release/TestFlight-style conditions while making small, targeted UX improvements required for real estimating workflows.

What is already true:
- SwiftUI iPad construction scope app exists
- Core section-based workflow exists
- Offline-first behavior remains important
- JobTread connectivity has been verified
- The app has additive model support for:
  - scopeTitle
  - jobTreadCustomer
  - jobTreadJob
  - jobTreadSync
- Scope naming has been separated from customer identity
- JobTread customer search/select path exists
- Live partial-name JobTread customer search works
- Selecting a JobTread customer creates a linked scope
- Linked-customer hydration works for verified fields
- Street-address normalization works in tested cases
- Unit number extraction from JobTread uses the correct fallback behavior when needed
- Verified JobTread-sourced customer/location fields are treated as read-only in the app
- Refresh/re-hydration from JobTread is the intended pattern for upstream customer/location changes
- A Documents / Attachments section exists with:
  - fixed Irrigation attachment slot
  - fixed Property Survey attachment slot
  - repeatable Additional Attachments
  - Files / Photo Library / Camera support
- Attachment source UX has been cleaned up so actions are context-aware and visually distinct
- A pricing/proposal foundation layer exists
- A debug-only inspector exists and can inspect the currently selected scope’s proposal/pricing foundation output
- Proposal composition, pricing rule registry, config foundation, returned pricing normalization, subtotal execution, aggregate scaffolding, and selected typed lookup families exist in the pricing domain layer
- Scope Title text entry now has a raw editable path separate from normalized display behavior so users can type normal spaces while editing
- PDF export/render/share pipeline has been hardened toward deterministic fixed-layout rendering with print-safe colors, page modeling, pagination, diagnostics, and attachment appendix handling
- Enclosure Type now supports multi-select behavior with dependent option visibility driven by selected type state
- Hidden Enclosure-dependent values may be preserved during editing and pruned from export/output when inactive
- Existing Conditions now supports nested multi-select behavior for Exterior Finish and multi-select behavior for Existing Structure
- Existing Conditions export/proposal output has already been updated to normalize/prune inactive hidden branch data for output
- Existing Conditions Photo Checklist now uses structured photo capture and file-backed checklist photo storage rather than tri-state status toggles
- Checklist photos can be added from Camera, Photo Library, and Files, persist across reopen, and are included in PDF export

Known limitations / current truths:
- The app is still primarily local-storage based
- Cross-device sync and multi-user shared company data are future backend/cloud concerns, not assumed solved now
- Same-device update continuity is the current target; reinstall/new-device continuity is not guaranteed
- Phone/email hydration from JobTread is still not verified from available docs/schema and should not be assumed
- Do not assume arbitrary uploaded PDFs can be parsed by JobTread into structured fields automatically
- Not every app field will necessarily map 1:1 to a native JobTread field
- Final structured JobTread sync submission is not implemented yet

Critical production-hardening findings:
- Same-device local continuity may be acceptable for one beta user if the app remains installed and the store remains readable
- There is no explicit SwiftData migration plan/versioning discipline yet
- Document payload persistence uses a custom JSON blob inside the model, which increases migration fragility
- Asset references use app-container file paths and are not a reinstall/new-device continuity strategy
- Release/TestFlight configuration needs to remain tightly controlled
- Secrets/config material must not be bundled into shipped app resources
- It is not yet honest to promise zero-loss continuity across future iterative builds unless release configuration and migration discipline are tightened first

Current architectural direction:
- JobTread is the source of truth for customer records
- The app should not create duplicate customers
- The app should not edit JobTread-owned customer master data locally unless a future phase explicitly verifies and adopts that behavior
- Linked JobTread customer/location fields should remain read-only in the app
- If JobTread customer/location data changes upstream, the app should support refreshing those fields into the linked local scope
- The scope app should become the source of truth for:
  - scope selections
  - proposal composition
  - estimate-relevant structured output
  - customer-facing proposal generation
- The app should derive both:
  - polished proposal/PDF output
  - future structured JobTread sync payloads
  from one shared structured pricing/proposal layer
- Pricing logic should live in a structured domain/config layer, not in SwiftUI views or the final PDF renderer
- Export/PDF generation should use a dedicated deterministic rendering path rather than relying on capturing live interactive UI when necessary
- Checklist photos should be treated as structured scope data, not generic attachments
- For the immediate field beta, same-device update continuity, release-safety hardening, and reliable core workflow UX are the primary targets
- For the long-term SaaS product, authenticated cloud-backed sync will likely be required for multi-device and multi-user business continuity

UI/input architecture guidance:
- User-facing editable text fields should not be aggressively normalized on every keystroke
- Prefer raw editable state for live text entry and normalize only at appropriate save/display boundaries
- For selection-heavy workflow areas, prefer state that clearly models the user’s actual intent rather than overloading single-select controls
- When one selection reveals dependent controls, the visibility of those controls should be driven by structured selection state, not fragile view-only conditionals
- Keep business logic out of Views; place reusable selection/update logic in model/view-model/service layers where appropriate
- For multi-select workflows with dependent controls, unselected branches may be temporarily preserved during editing for user convenience
- Hidden preserved values must not leak into final output
- Export-time data should be normalized/pruned so only currently active selections and their visible dependent values are included
- Required text fields that are revealed by selecting an Other option should be clearly labeled to indicate which Other selection they belong to
- Photo-heavy UI should feel first-party Apple-like, visually calm, and easy to scan in the field
- Prefer inline expansion/collapse and clean thumbnail presentation over heavy modal complexity when possible
- Structural System should be implemented as a progressive-disclosure decision tree rather than a flat collection of unrelated pickers

Immediate implementation direction:
- Preserve current production stability
- Make targeted real-workflow improvements only when they are clearly needed by field testing
- Replace the current Structural System section with the client-approved branching workflow
- Keep the first pass practical and capture-oriented rather than overly automated
- Ensure inactive branch data is excluded from export/output
- Keep the implementation incremental and production-safe
- Defer broader cloud-sync architecture to a future phase

Most relevant near-term hardening / workflow domains:
- PDF export/render/share correctness on physical iPad hardware
- explicit export page sizing and deterministic layout composition
- attachment/image layout constraints during export
- export diagnostics and validation
- Release/TestFlight configuration correctness
- Info.plist/config resolution safety
- secret/config resource handling
- startup behavior when config is missing or unresolved
- persistence-shape freeze / migration discipline
- continuity test procedure for build-to-build upgrades
- near-term backup/export/recovery planning
- stable section workflows for real estimators, including branching section logic, structured checklist photo capture, and progressive disclosure

Current priorities:
1. Preserve build stability and core field-beta workflow reliability
2. Support real estimator workflows with targeted UX fixes in Structural System, Existing Conditions, and related section flows
3. Preserve recent Enclosure and Existing Conditions selection architecture consistency
4. Preserve PDF export/render/share reliability for real field beta use while expanding structured section output cleanly
5. Preserve Release/TestFlight launch/configuration safety
6. Remove bundled secret/config resource risks
7. Identify and reduce release-blocking continuity risks
8. Define what persistence/model changes must be frozen or migration-reviewed during beta
9. Prepare for one trusted same-device field beta user
10. Clearly avoid overpromising reinstall/new-device/multi-user continuity
11. Keep this phase production-hardening focused, not feature-expansion focused

Editing rules:
- Follow READ → PLAN → EDIT
- Make surgical edits
- Do not rewrite large files unnecessarily
- Preserve working service and model boundaries
- Explain what files changed and why
- Prefer incremental, production-safe changes over broad refactors
- Keep business logic out of Views
- Do not refactor unrelated working areas while fixing a targeted workflow issue
- This phase is production-hardening first, not feature-first
