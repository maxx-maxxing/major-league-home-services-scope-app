Read codex_context.md before making changes.

Current working focus:
Audit the app for TestFlight/release continuity and persistence safety before real field beta use.

Highest-priority requirement:
When the app is distributed through TestFlight and updated with new builds, the user must lose zero progress. Existing scopes, entered field data, signatures, sketches, photos, document attachments, and other persisted work must survive app updates safely.

Important constraint:
Do not destabilize the current working JobTread customer search/select, linked-customer hydration, verified read-only ownership behavior, Documents / Attachments section, pricing engine, returned pricing normalization/validation path, or debug inspector unless the task explicitly requires it.

Current app phase:
The app is functionally advanced enough that a real field beta is about to begin. Before broader use, the top priority is to audit persistence, model stability, attachment durability, and update continuity so the app is safe to hand to a real user through TestFlight.

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
- Proposal composition includes:
  - customer-facing sections
  - internal-only sections
  - future sync candidates
  - placeholder pricing groups and buckets
  - section inclusion rules
- Pricing buckets, rule registry, config foundation, returned pricing normalization, subtotal execution, aggregate scaffolding, and selected typed lookup families exist in the pricing domain layer

Known limitations / current truths:
- The app is likely still primarily local-storage based today
- Cross-device sync and multi-user shared company data should be considered a future backend/cloud architecture problem, not assumed solved today
- Phone/email hydration from JobTread is still not verified from the available docs/schema and should not be assumed
- Do not assume arbitrary uploaded PDFs can be parsed by JobTread to populate structured fields automatically
- Not every app field will necessarily map 1:1 to a native JobTread field
- Final polished PDF rendering is not implemented yet
- Final structured JobTread sync submission is not implemented yet
- Multi-device continuity and multi-user account sync are desired end-state goals, but may not yet exist in the current implementation

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
- For the immediate field beta, same-device update continuity and local persistence durability are the primary audit targets

Immediate implementation/audit direction:
- Audit the current persistence model before real field distribution
- Determine whether local data is durable across TestFlight build updates
- Determine whether attachments, signatures, sketches, photos, and other artifacts are stored safely
- Determine whether SwiftData/model/schema evolution is likely to endanger existing user data during iteration
- Identify what must be frozen, changed carefully, or protected before handing the app to a real field user
- Separate:
  - safe-for-now same-device TestFlight continuity
  - future cross-device/company-wide sync requirements

Most relevant near-term audit domains:
- SwiftData model/schema migration risk
- local persistence durability
- attachment/file storage durability
- photo/signature/sketch persistence behavior
- update continuity across builds
- reinstall vs update expectations
- release configuration differences
- backup/export/recovery strategy
- future backend/cloud sync requirements

Current priorities:
1. Audit same-device TestFlight update safety
2. Audit local persistence durability for all critical user data
3. Audit attachment/photo/signature/sketch/file persistence
4. Identify schema/model migration risks that could cause data loss during updates
5. Identify release-blocking issues before real beta use
6. Clearly distinguish what is safe today vs what requires future cloud/backend work
7. Avoid speculative implementation in this pass; prioritize a truthful audit first

Editing rules:
- Follow READ → PLAN → EDIT
- Make surgical edits
- Do not rewrite large files unnecessarily
- Preserve working service and model boundaries
- Explain what files changed and why
- Prefer incremental, production-safe changes over broad refactors
- Keep business logic out of Views
- This next phase is audit-first, not implementation-first
