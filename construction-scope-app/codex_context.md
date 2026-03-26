Read codex_context.md before making changes.

Current working focus:
Turning the existing proposal/pricing foundation into a usable proposal composition layer with placeholder cost groups and inclusion logic.

Important constraint:
Do not destabilize the current working JobTread customer search/select, linked-customer hydration, verified read-only ownership behavior, Documents / Attachments section, or debug inspector unless the task explicitly requires it.

Current app phase:
The JobTread-first customer linking flow is working. A first pricing/proposal foundation exists. The next phase is to make that foundation structurally useful for proposal generation before final pricing and final PDF rendering are added.

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

Known limitations / current truths:
- Phone/email hydration from JobTread is still not verified from the available docs/schema and should not be assumed
- Do not assume arbitrary uploaded PDFs can be parsed by JobTread to populate structured fields automatically
- Not every app field will necessarily map 1:1 to a native JobTread field
- Full real pricing and final cost group definitions from the business are not complete yet
- Final polished PDF rendering is not implemented yet
- Final structured JobTread sync is not implemented yet

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

Target end-state workflow:
1. Search/select existing JobTread customer
2. Pull linked customer/location data into the scope
3. Capture scope details and estimate-relevant selections in the app
4. Run pricing/estimate calculations from a structured rules/config layer
5. Build proposal composition from structured app data
6. Generate a polished customer-facing PDF proposal in-app
7. Sync as much structured data as possible directly into JobTread where supported
8. Upload generated PDF and related files to JobTread as attachments where appropriate
9. Keep signatures embedded visually in the generated proposal/PDF unless a future phase explicitly adopts JobTread-native signature workflows

Proposal-generation guidance:
- Prefer direct API sync for structured data and file upload for presentation artifacts
- Do not design around “upload PDF and let JobTread backfill itself”
- Treat PDF generation and structured JobTread sync as related but separate outputs from the same scope data
- Pricing formulas should live in a structured rules/calculation layer, not in the final PDF itself
- Proposal composition should be built from structured data, not assembled ad hoc inside the PDF renderer
- The first pricing/proposal foundation should be easy to edit as:
  - supplier/vendor costs change
  - option names change
  - new offerings are added
  - proposal wording/section visibility changes

Immediate implementation direction:
- Build the proposal composition layer next
- Add placeholder cost groups and pricing buckets even before final real pricing is available
- Define inclusion rules so proposal sections appear only when relevant to the current scope
- Distinguish clearly between:
  - customer-facing proposal content
  - internal-only data
  - future JobTread sync candidates
- Avoid hardcoding pricing logic directly in SwiftUI views or PDF rendering code

Most relevant near-term domains to build:
- proposal composition model
- proposal section definitions
- inclusion / visibility rules
- placeholder cost groups
- pricing bucket/group scaffolding
- sync mapping matrix
- future PDF rendering inputs

Current priorities:
1. Turn the existing foundation into a real proposal composition model
2. Add placeholder cost groups / pricing buckets that mirror the current scope structure
3. Define section inclusion/visibility rules from current scope selections
4. Separate:
   - raw scope capture
   - pricing rules/config
   - proposal composition
   - PDF rendering
   - future JobTread sync outputs
5. Preserve current working customer lookup/hydration/read-only behavior
6. Continue UI/data-entry refinement without disrupting the integration baseline
7. Avoid guessing unsupported JobTread behaviors, especially PDF-import parsing and unverified field ownership

Editing rules:
- Follow READ → PLAN → EDIT
- Make surgical edits
- Do not rewrite large files unnecessarily
- Preserve working service and model boundaries
- Treat schema/model updates correctly when adding persisted fields
- Explain what files changed and why
- Prefer incremental, production-safe changes over broad refactors
- Keep business logic out of Views
