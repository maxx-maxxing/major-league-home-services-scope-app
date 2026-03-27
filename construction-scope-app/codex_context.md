Read codex_context.md before making changes.

Current working focus:
Moving the pricing engine from safe placeholder/deferred behavior into the first real typed lookup-table execution for selected deferred bucket families.

Important constraint:
Do not destabilize the current working JobTread customer search/select, linked-customer hydration, verified read-only ownership behavior, Documents / Attachments section, returned pricing normalization/validation path, or debug inspector unless the task explicitly requires it.

Current app phase:
The JobTread-first customer linking flow is working. Proposal composition exists. Bucket-level draft subtotal execution exists for directly supported strategies. Group and proposal total scaffolding now exist. The next phase is to convert one or two high-confidence deferred bucket families into typed lookup-table execution.

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
- Imported structured pricing rows can hydrate pricing configuration snapshots by stable rule ID while falling back safely to the embedded baseline
- A business-facing pricing intake deliverable exists
- Returned-sheet normalization and validation exist
- Bucket-level draft subtotal execution exists for directly supported strategies
- Group total scaffolding exists
- Proposal total scaffolding exists
- The debug inspector can display:
  - returned-sheet status
  - rule resolution
  - config source
  - pricing seed/config details
  - bucket subtotal readiness
  - derivation/source metadata
  - missing inputs
  - calculation trace
  - group total readiness/amount/trace
  - proposal total readiness/amount/trace
- Current validation confirms the engine now safely supports:
  - calculated buckets
  - partial group totals
  - missing-input aggregate states

Known limitations / current truths:
- Phone/email hydration from JobTread is still not verified from the available docs/schema and should not be assumed
- Do not assume arbitrary uploaded PDFs can be parsed by JobTread to populate structured fields automatically
- Not every app field will necessarily map 1:1 to a native JobTread field
- Final polished PDF rendering is not implemented yet
- Final structured JobTread sync submission is not implemented yet
- Final real business pricing has not been returned yet
- Several deferred/lookup-style bucket families still do not execute
- Some quantity seeds such as area/perimeter are not yet fully trusted or normalized for all affected families
- Group/proposal totals remain only as strong as the child bucket execution beneath them

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
- Totals should be built progressively:
  - bucket subtotals
  - group totals
  - proposal totals
before final preview/PDF/sync work
- Deferred buckets should be converted gradually into typed executable strategies only when the input contract is clear and trustworthy

Target end-state workflow:
1. Search/select existing JobTread customer
2. Pull linked customer/location data into the scope
3. Capture scope details and estimate-relevant selections in the app
4. Collect/normalize business-owned pricing data through the structured pricing intake/import boundary
5. Resolve pricing rules from the structured rules/config layer
6. Execute bucket-level draft subtotals
7. Execute typed lookup-table strategies for deferred bucket families
8. Roll up group totals and proposal totals
9. Build proposal composition from structured app data
10. Generate a polished customer-facing PDF proposal in-app
11. Sync as much structured data as possible directly into JobTread where supported
12. Upload generated PDF and related files to JobTread as attachments where appropriate
13. Keep signatures embedded visually in the generated proposal/PDF unless a future phase explicitly adopts JobTread-native signature workflows

Proposal-generation guidance:
- Prefer direct API sync for structured data and file upload for presentation artifacts
- Do not design around “upload PDF and let JobTread backfill itself”
- Treat PDF generation and structured JobTread sync as related but separate outputs from the same scope data
- Pricing formulas should live in a structured rules/calculation layer, not in the final PDF itself
- Proposal composition should be built from structured data, not assembled ad hoc inside the PDF renderer
- Real pricing values should remain externally configurable and business-owned
- Stable rule IDs and schedule-input keys are the import boundary for future spreadsheet/CSV/JSON pricing data
- Bucket subtotals, group totals, and proposal totals should remain explainable and traceable in the debug inspector before final presentation/export phases are built

Immediate implementation direction:
- Build typed lookup-table execution for one or two high-confidence deferred families
- Prefer the smallest safe domains first, where:
  - quantity basis is already reasonably trusted
  - schedule inputs are already visible in the inspector
  - business logic can be represented as a typed contract rather than vague notes
- Keep the first typed execution pass separate from:
  - final proposal preview UI
  - final PDF rendering
  - final JobTread pricing sync submission
- Avoid broad conversion of every deferred bucket at once
- Avoid hardcoding business logic directly in SwiftUI views or PDF rendering code

Most relevant near-term domains to build:
- typed lookup-table execution
- schedule/tier contract typing
- quantity basis normalization for selected families
- deferred bucket family conversion
- aggregate readiness improvements
- future proposal preview inputs
- future PDF rendering inputs
- future JobTread sync inputs

Current priorities:
1. Convert one or two high-confidence deferred bucket families into typed lookup execution
2. Keep unsupported deferred families explicitly deferred and explainable
3. Improve quantity/input trustworthiness only where needed for the selected families
4. Surface typed lookup execution and remaining deferrals clearly in the debug inspector
5. Preserve current working customer lookup/hydration/read-only behavior
6. Continue evolving pricing architecture without disrupting the integration baseline
7. Avoid guessing unsupported JobTread behaviors, especially PDF-import parsing and unverified field ownership
8. Avoid overcommitting to final business pricing details before business inputs are confirmed

Editing rules:
- Follow READ → PLAN → EDIT
- Make surgical edits
- Do not rewrite large files unnecessarily
- Preserve working service and model boundaries
- Treat schema/model updates correctly when adding persisted fields
- Explain what files changed and why
- Prefer incremental, production-safe changes over broad refactors
- Keep business logic out of Views
