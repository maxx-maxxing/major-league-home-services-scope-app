Read codex_context.md before making changes.

Current working focus:
Producing the first business-owned pricing intake deliverable that my brother can fill out and hand back so real pricing can be plugged into the app with minimal rework.

Important constraint:
Do not destabilize the current working JobTread customer search/select, linked-customer hydration, verified read-only ownership behavior, Documents / Attachments section, or debug inspector unless the task explicitly requires it.

Current app phase:
The JobTread-first customer linking flow is working. Proposal composition exists. Pricing buckets carry seed/config metadata. A pricing rule registry exists. An external pricing configuration foundation and first JSON import boundary now exist. The next phase is to turn that internal architecture into a real business-facing pricing intake deliverable.

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
- A first machine-readable JSON import boundary exists
- Imported structured pricing rows can hydrate pricing configuration snapshots by stable rule ID while falling back safely to the embedded baseline

Known limitations / current truths:
- Phone/email hydration from JobTread is still not verified from the available docs/schema and should not be assumed
- Do not assume arbitrary uploaded PDFs can be parsed by JobTread to populate structured fields automatically
- Not every app field will necessarily map 1:1 to a native JobTread field
- Full real pricing and final business cost group definitions are not complete yet
- Final polished PDF rendering is not implemented yet
- Final structured JobTread sync submission is not implemented yet
- Real business-owned pricing intake template/deliverable for my brother is not finished yet
- CSV normalization/import is not implemented yet
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
- Real business pricing should enter the system through a structured business-owned intake/import boundary keyed by stable rule IDs

Target end-state workflow:
1. Search/select existing JobTread customer
2. Pull linked customer/location data into the scope
3. Capture scope details and estimate-relevant selections in the app
4. Collect business-owned pricing data through a structured pricing intake template
5. Normalize that pricing data into the app’s stable imported row contract
6. Resolve pricing rules from the structured rules/config layer
7. Build proposal composition from structured app data
8. Generate draft subtotals, group totals, and eventually proposal totals
9. Generate a polished customer-facing PDF proposal in-app
10. Sync as much structured data as possible directly into JobTread where supported
11. Upload generated PDF and related files to JobTread as attachments where appropriate
12. Keep signatures embedded visually in the generated proposal/PDF unless a future phase explicitly adopts JobTread-native signature workflows

Proposal-generation guidance:
- Prefer direct API sync for structured data and file upload for presentation artifacts
- Do not design around “upload PDF and let JobTread backfill itself”
- Treat PDF generation and structured JobTread sync as related but separate outputs from the same scope data
- Pricing formulas should live in a structured rules/calculation layer, not in the final PDF itself
- Proposal composition should be built from structured data, not assembled ad hoc inside the PDF renderer
- Real pricing values should remain externally configurable and business-owned
- Stable rule IDs and schedule-input keys are the import boundary for future spreadsheet/CSV/JSON pricing data
- The business-facing pricing deliverable must be easy to read, easy to fill out, and clearly mappable back into the app

Immediate implementation direction:
- Finish everything needed to hand my brother a real pricing intake deliverable
- This pass should define:
  - the business-facing pricing sheet/template structure
  - the exact columns/fields he needs to fill out
  - how those fields map back to stable rule IDs and optional schedule-input keys
  - how blank/optional values should be handled
  - what supporting documentation/instructions need to accompany the sheet
- Prefer a spreadsheet-first deliverable if that is the clearest business-owned format
- The resulting deliverable should be something I can immediately hand to my brother, have him fill out, then bring back to Codex/ChatGPT for plug-and-play incorporation

Most relevant near-term domains to build:
- pricing intake/export contract
- business-facing pricing spreadsheet/template
- row normalization contract
- import validation expectations
- rule ID / group ID reference guidance
- business instructions / fill guide
- future CSV normalization path
- future subtotal/group-total derivation from imported values

Current priorities:
1. Produce the business-owned pricing intake deliverable
2. Define the exact structured row/column contract my brother will fill out
3. Align the business-facing template with stable rule IDs and existing pricing buckets
4. Add whatever docs/samples/templates are needed so the filled deliverable can later be plugged in with minimal friction
5. Preserve current working customer lookup/hydration/read-only behavior
6. Continue evolving pricing architecture without disrupting the integration baseline
7. Avoid guessing unsupported JobTread behaviors, especially PDF-import parsing and unverified field ownership
8. Avoid overcommitting to incomplete final totals logic before business inputs are confirmed

Editing rules:
- Follow READ → PLAN → EDIT
- Make surgical edits
- Do not rewrite large files unnecessarily
- Preserve working service and model boundaries
- Treat schema/model updates correctly when adding persisted fields
- Explain what files changed and why
- Prefer incremental, production-safe changes over broad refactors
- Keep business logic out of Views
