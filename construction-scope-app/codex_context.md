Read codex_context.md before making changes.

Current working focus:
Production-hardening for TestFlight field beta distribution, with immediate emphasis on fixing PDF export reliability on real iPad hardware.

Highest-priority bug focus:
- A real field tester reported that exporting/sharing a scope as PDF can generate multiple mostly blank pages
- In the bad output, an attached image may appear randomly while the intended scope content is missing
- Audit the full PDF export/render/share pipeline end to end
- Determine whether export is incorrectly rendering:
  - a live interactive SwiftUI screen instead of a dedicated export view
  - unconstrained ScrollView / lazy content
  - incorrect fixed page sizing or layout bounds
  - attachment/image content that breaks pagination or dominates layout
- Move toward deterministic export rendering with explicit page layout and flattened output
- Add targeted export diagnostics/logging for page count, rendered sections, and attachment inclusion
- Fix the bug without destabilizing:
  - JobTread customer search/select
  - linked-customer hydration
  - read-only JobTread-owned data behavior
  - Documents / Attachments workflows
  - pricing/proposal foundation
  - debug inspector

Important constraint:
Do not destabilize the current working JobTread customer search/select, linked-customer hydration, verified read-only ownership behavior, Documents / Attachments section, pricing engine, returned pricing normalization/validation path, or debug inspector unless the task explicitly requires it.

Current app phase:
The app is advanced enough for real field beta use, but production hardening is still in progress. Current work should prioritize reliability in Release/TestFlight-style conditions before broader feature expansion.

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

Known limitations / current truths:
- The app is still primarily local-storage based
- Cross-device sync and multi-user shared company data are future backend/cloud concerns, not assumed solved now
- Same-device update continuity is the current target; reinstall/new-device continuity is not guaranteed
- Phone/email hydration from JobTread is still not verified from available docs/schema and should not be assumed
- Do not assume arbitrary uploaded PDFs can be parsed by JobTread into structured fields automatically
- Not every app field will necessarily map 1:1 to a native JobTread field
- Final structured JobTread sync submission is not implemented yet
- PDF export currently exists but is not yet trustworthy enough to treat as production-safe until the real-device blank-page bug is resolved

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
- For the immediate field beta, same-device update continuity, release-safety hardening, and PDF export reliability are the primary targets
- For the long-term SaaS product, authenticated cloud-backed sync will likely be required for multi-device and multi-user business continuity

Immediate implementation direction:
- Fix PDF export/render/share reliability first
- Harden Release/TestFlight launch/configuration
- Remove any shipped secret/config resource mistakes
- Make launch behavior safe in Release/TestFlight-style builds
- Reduce avoidable persistence risk during the beta window
- Add enough operational guardrails that one trusted field beta user can test safely on a single installed device
- Defer broader cloud-sync architecture to a future phase

Most relevant near-term hardening domains:
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
- distinction between:
  - safe same-device update continuity
  - unsafe reinstall/new-device continuity
  - future cloud/backend sync requirements

Current priorities:
New active UI/input bug:
- In the Project Information section, the Scope Title text field currently rejects spaces during typing on the tester’s real iPad
- Scope Title must behave as a normal freeform user-facing text field
- Do not apply aggressive trimming/sanitization on each keystroke for this field
- If normalization is required, it should happen at an appropriate commit/save/display boundary rather than during live text entry

Near-term bug-fix expectation:
- Audit the full data flow for Scope Title:
  - SwiftUI TextField binding
  - onChange / setter behavior
  - ViewModel update path
  - model persistence/update path
  - any shared text normalization helpers
- Fix the bug surgically without destabilizing:
  - Project Information editing
  - linked JobTread customer display
  - scope list/editor header display
  - persistence/autosave behavior

Editing rules:
- Follow READ → PLAN → EDIT
- Make surgical edits
- Do not rewrite large files unnecessarily
- Preserve working service and model boundaries
- Explain what files changed and why
- Prefer incremental, production-safe changes over broad refactors
- Keep business logic out of Views
- Do not refactor unrelated working areas while fixing a targeted production bug
- This phase is production-hardening first, not feature-first
