Read codex_context.md before making changes.

Current working focus:
Production-hardening for TestFlight field beta distribution, while continuing small, surgical workflow improvements that directly support real field use.

Current active feature task:
Update the Existing Conditions section so Exterior Finish and Existing Structure match the business workflow more accurately.

Required Existing Conditions behavior:

Exterior Finish:
- The current single Exterior Finish selector is no longer sufficient
- Replace the current Exterior Finish behavior with a first-level multi-select that allows selecting any combination of:
  - Posts/Columns
  - Exterior House Wall
- These first-level Exterior Finish options must each be independently selectable and unselectable
- If Posts/Columns is selected, a dependent multi-select material control must appear for Posts/Columns with:
  - Wood
  - Brick
  - Stone
  - Hardie
- If Exterior House Wall is selected, a dependent multi-select material control must appear for Exterior House Wall with:
  - Wood
  - Vinyl
  - Brick
  - Stone
  - Hardie
  - LP Siding
  - Other
- If Exterior House Wall -> Other is selected, a required text field must appear that clearly refers to that specific Other selection
- If Posts/Columns is selected, two additional dependent controls must also appear:
  - Post Trim = yes/no
  - Trim Thickness = free text field
- Nested selections should support multiple simultaneous selections where applicable
- The UI should make parent/child relationships obvious and field-friendly

Existing Structure:
- Keep the current Existing Structure option list
- Change Existing Structure from single-select to multi-select
- The user must be able to select any combination of Existing Structure options
- No new dependent fields are required for Existing Structure at this time

Hidden/dependent state behavior:
- If a parent option is unselected, its dependent child controls must disappear from the UI
- Hidden dependent values should be temporarily preserved while the user is still editing
- Hidden preserved values must not be treated as active data for output generation
- On PDF export / proposal output, hidden inactive values must be pruned so they are not included in exported output and do not remain as lingering hidden state afterward
- This hidden-state behavior should remain consistent with the recent Enclosure multi-select pattern where practical

Important constraint:
Do not destabilize the current working JobTread customer search/select, linked-customer hydration, verified read-only ownership behavior, Documents / Attachments section, pricing engine, returned pricing normalization/validation path, debug inspector, PDF export pipeline, recent Scope Title text-entry fix, or recent Enclosure multi-select work unless the task explicitly requires it.

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

Immediate implementation direction:
- Preserve current production stability
- Make targeted real-workflow improvements only when they are clearly needed by field testing
- Update Existing Conditions so Exterior Finish supports nested multi-select behavior and Existing Structure supports multi-select behavior
- Ensure dependent Existing Conditions options appear/disappear based on current selected parent state
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
- stable section workflows for real estimators, including multi-select-driven dependent option groups

Current priorities:
1. Preserve build stability and core field-beta workflow reliability
2. Support real estimator workflows with targeted UX fixes in Existing Conditions and related section flows
3. Preserve recent Enclosure multi-select behavior and architectural consistency
4. Preserve PDF export/render/share reliability for real field beta use
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
