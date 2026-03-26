Read codex_context.md before making changes.

Current working focus:
Building the app toward a proposal-generation workflow that minimizes duplicate entry between the scope app and JobTread.

Important constraint:
Do not destabilize the current working JobTread customer search/select, linked-customer hydration, verified read-only ownership behavior, or recently added Documents / Attachments section unless the task explicitly requires it.

Current app phase:
The JobTread-first customer linking flow is working. The app is now moving toward a hybrid proposal-generation + structured JobTread sync architecture.

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
- Unit number extraction from JobTread now uses the correct fallback behavior when needed
- JobTread-sourced verified customer/location fields are treated as read-only in the app
- Refresh/re-hydration from JobTread is the intended pattern for upstream customer/location changes
- A Documents / Attachments section now exists with:
  - fixed Irrigation attachment slot
  - fixed Property Survey attachment slot
  - repeatable Additional Attachments
  - Files / Photo Library / Camera support
- Attachment source UX has been cleaned up so actions are context-aware and visually distinct

Known limitations / current truths:
- Phone/email hydration from JobTread is still not verified from the available docs/schema and should not be assumed
- Do not assume arbitrary uploaded PDFs can be parsed by JobTread to populate structured fields automatically
- Some future scope fields may not map 1:1 to native JobTread fields and may require custom fields or file/PDF-only output

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

Target end-state workflow:
1. Search/select existing JobTread customer
2. Pull linked customer/location data into the scope
3. Capture scope details and estimate-relevant selections in the app
4. Compute pricing/estimate output from a structured rules layer
5. Generate a polished customer-facing PDF proposal from the scope
6. Sync as much structured data as possible directly into JobTread where supported
7. Upload generated PDF and related files to JobTread as attachments where appropriate
8. Keep signatures embedded visually in the generated proposal/PDF unless a future phase explicitly adopts JobTread-native signature workflows

Proposal-generation guidance:
- Prefer direct API sync for structured data and file upload for presentation artifacts
- Do not design around “upload PDF and let JobTread backfill itself”
- Treat PDF generation and structured JobTread sync as related but separate outputs from the same scope data
- Pricing formulas should live in a structured rules/calculation layer, not in the final PDF itself

Most relevant JobTread sync targets to evaluate:
- Job
- Document
- Cost Groups / Cost Items / Line Items
- Custom Fields
- File attachments
- Native document/signature workflows only if clearly beneficial and supported

Current priorities:
1. Audit and define which scope fields map directly to JobTread job/document/cost data
2. Define the best proposal-generation architecture
3. Separate:
   - structured sync targets
   - PDF-only presentation data
4. Preserve current working customer lookup/hydration/read-only behavior
5. Continue UI/data-entry refinement without disrupting the integration baseline
6. Avoid guessing unsupported JobTread behaviors, especially PDF-import parsing and unverified field ownership

Editing rules:
- Follow READ → PLAN → EDIT
- Make surgical edits
- Do not rewrite large files unnecessarily
- Preserve working service and model boundaries
- Treat schema/model updates correctly when adding persisted fields
- Explain what files changed and why
- Prefer incremental, production-safe changes over broad refactors
