Read codex_context.md before making changes.

Current working focus:
Building the first real import boundary for business-owned pricing data so placeholder pricing config can be replaced by structured external pricing inputs without redesigning the pricing system.

Important constraint:
Do not destabilize the current working JobTread customer search/select, linked-customer hydration, verified read-only ownership behavior, Documents / Attachments section, or debug inspector unless the task explicitly requires it.

Current app phase:
The JobTread-first customer linking flow is working. Proposal composition exists. Pricing buckets carry seed/config metadata. A pricing rule registry exists. An external pricing configuration foundation now exists. The next phase is to create the first import boundary for business-owned pricing data.

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
- Each pricing bucket carries structured draft seed/config metadata
- A pricing rule registry exists
- A separate external pricing configuration foundation exists
- Buckets can now resolve config-fed draft values and subtotal-readiness scaffolding from an embedded draft pricing snapshot

Known limitations / current truths:
- Phone/email hydration from JobTread is still not verified from the available docs/schema and should not be assumed
- Do not assume arbitrary uploaded PDFs can be parsed by JobTread to populate structured fields automatically
- Not every app field will necessarily map 1:1 to a native JobTread field
- Full real pricing and final business cost group definitions are not complete yet
- Final polished PDF rendering is not implemented yet
- Final structured JobTread sync submission is not implemented yet
- Real spreadsheet/CSV/JSON import of business pricing is not implemented yet
- Final totals engine and final proposal totals are not implemented yet

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
- Real business pricing should enter the system through a structured import/config boundary keyed by stable rule IDs

Target end-state workflow:
1. Search/select existing JobTread customer
2. Pull linked customer/location data into the scope
3. Capture scope details and estimate-relevant selections in the app
4. Import/configure business-owned pricing data through a structured pricing boundary
5. Resolve pricing rules from a structured rules/config layer
6. Build proposal composition from structured app data
7. Generate draft subtotals, group totals, and eventually proposal totals
8. Generate a polished customer-facing PDF proposal in-app
9. Sync as much structured data as possible directly into JobTread where supported
10. Upload generated PDF and related files to JobTread as attachments where appropriate
11. Keep signatures embedded visually in the generated proposal/PDF unless a future phase explicitly adopts JobTread-native signature workflows

Proposal-generation guidance:
- Prefer direct API sync for structured data and file upload for presentation artifacts
- Do not design around “upload PDF and let JobTread backfill itself”
- Treat PDF generation and structured JobTread sync as related but separate outputs from the same scope data
- Pricing formulas should live in a structured rules/calculation layer, not in the final PDF itself
- Proposal composition should be built from structured data, not assembled ad hoc inside the PDF renderer
- Real pricing values should remain externally configurable and business-owned
- Stable rule IDs and schedule-input keys are the import boundary for future spreadsheet/CSV/JSON pricing data

Immediate implementation direction:
- Build the first import boundary for business-owned pricing data next
- Support a structured import shape keyed by stable rule IDs and optional schedule-input keys
- Keep this import boundary separate from:
  - raw scope capture
  - rule definitions
  - proposal section composition
  - final PDF rendering
  - final JobTread sync submission
- The first pass should focus on architecture and safe ingestion, not polished editing UI
- Avoid hardcoding business logic directly in SwiftUI views or PDF rendering code

Most relevant near-term domains to build:
- pricing import model
- CSV/JSON/spreadsheet-shaped adapter boundary
- config snapshot hydration from imported rows
- validation/status reporting for imported pricing rows
- subtotal derivation from imported config
- future group total scaffolding
- future PDF rendering inputs
- future JobTread sync inputs

Current priorities:
1. Build the first import boundary for business-owned pricing data
2. Support a structured row model keyed by stable rule ID
3. Hydrate pricing configuration snapshots from imported data
4. Surface import/validation status in the debug inspector if useful
5. Preserve current working customer lookup/hydration/read-only behavior
6. Continue UI/data-entry refinement without disrupting the integration baseline
7. Avoid guessing unsupported JobTread behaviors, especially PDF-import parsing and unverified field ownership
8. Avoid overcommitting to incomplete real pricing details before business inputs are final

Editing rules:
- Follow READ → PLAN → EDIT
- Make surgical edits
- Do not rewrite large files unnecessarily
- Preserve working service and model boundaries
- Treat schema/model updates correctly when adding persisted fields
- Explain what files changed and why
- Prefer incremental, production-safe changes over broad refactors
- Keep business logic out of Views
