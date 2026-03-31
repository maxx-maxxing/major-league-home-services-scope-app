Read codex_context.md before making changes.

Current working focus:
Release-hardening for TestFlight field beta distribution.

Highest-priority requirement:
A real user is about to start using the app in the field through TestFlight. Before distribution, the app must be hardened so same-device TestFlight updates are as safe as possible and do not unexpectedly break launch, wipe local progress, or lose critical user data.

Important constraint:
Do not destabilize the current working JobTread customer search/select, linked-customer hydration, verified read-only ownership behavior, Documents / Attachments section, pricing engine, returned pricing normalization/validation path, or debug inspector unless the task explicitly requires it.

Current app phase:
The app is functionally advanced enough for a real field beta, but a persistence/release-readiness audit found concrete TestFlight risks. The next phase is to harden release configuration and continuity safety before handing the app to a real field user.

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
- JobTread customer search/select creation path exists
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
- The app is likely still primarily local-storage based today
- Cross-device sync and multi-user shared company data should be considered a future backend/cloud architecture problem, not assumed solved today
- Same-device update continuity is the current target; reinstall/new-device continuity is not currently guaranteed
- Phone/email hydration from JobTread is still not verified from the available docs/schema and should not be assumed
- Do not assume arbitrary uploaded PDFs can be parsed by JobTread to populate structured fields automatically
- Not every app field will necessarily map 1:1 to a native JobTread field
- Final polished PDF rendering is not implemented yet
- Final structured JobTread sync submission is not implemented yet

Critical audit findings from the latest continuity review:
- Same-device local continuity may be acceptable for one beta user if the app remains installed and the store remains readable
- There is no explicit SwiftData migration plan/versioning discipline yet
- Document payload persistence uses a custom JSON blob inside the model, which increases migration fragility
- Asset references use app-container file paths and are not a reinstall/new-device continuity strategy
- Release/TestFlight configuration is currently unsafe
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
- For the long-term SaaS product, authenticated cloud-backed sync will likely be required for multi-device and multi-user business continuity
- For the immediate field beta, same-device update continuity and release-safety hardening are the primary targets

Immediate implementation direction:
- Harden Release/TestFlight launch/configuration first
- Remove any shipped secret/config resource mistakes
- Make launch behavior safe in Release/TestFlight-style builds
- Reduce avoidable persistence risk during the beta window
- Add enough operational guardrails that one trusted field beta user can test safely on a single installed device
- Defer broader cloud-sync architecture to a future phase

Most relevant near-term hardening domains:
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
1. Fix Release/TestFlight configuration and launch safety
2. Remove bundled secret/config resource risks
3. Identify and reduce release-blocking continuity risks
4. Define what persistence/model changes must be frozen or migration-reviewed during beta
5. Prepare for one trusted same-device field beta user
6. Clearly avoid overpromising reinstall/new-device/multi-user continuity
7. Keep this phase release-hardening focused, not feature-expansion focused

Editing rules:
- Follow READ → PLAN → EDIT
- Make surgical edits
- Do not rewrite large files unnecessarily
- Preserve working service and model boundaries
- Explain what files changed and why
- Prefer incremental, production-safe changes over broad refactors
- Keep business logic out of Views
- This phase is release-hardening first, not feature-first
