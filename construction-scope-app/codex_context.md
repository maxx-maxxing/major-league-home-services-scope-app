Read codex_context.md before making changes.

Current working focus:
JobTread customer contact hydration audit and implementation.

Highest-priority requirement:
When a JobTread customer is selected in the app, the in-app linked scope should hydrate not only address/location details but also the customer’s phone number and email when JobTread actually provides them. Those values should then appear:
- in the scope UI
- in the exported PDF header/customer block

Important constraint:
Do not destabilize the current working JobTread customer search/select, linked-customer hydration, verified read-only ownership behavior, Documents / Attachments section, pricing engine, persistence continuity fixes, or current PDF export filtering/layout improvements unless the task explicitly requires it.

Current app phase:
PDF export filtering/layout work has reached a reasonable stopping point for now. The next active phase is to strengthen JobTread customer hydration so phone number and email can be pulled into the linked scope and included in the PDF output when available from JobTread.

What is already true:
- SwiftUI iPad construction scope app exists
- Core section-based workflow exists
- Offline-first behavior remains important
- JobTread connectivity has been verified
- Scope naming has been separated from customer identity
- JobTread customer search/select creation path exists
- Live partial-name JobTread customer search works
- Selecting a JobTread customer creates a linked scope
- Linked-customer hydration already works for some verified fields such as customer name and address/location information
- Street-address normalization works in tested cases
- Unit number extraction from JobTread uses the correct fallback behavior when needed
- Verified JobTread-sourced customer/location fields are treated as read-only in the app
- Refresh/re-hydration from JobTread is the intended pattern for upstream customer/location changes
- Current PDF export now includes only relevant scope content and has improved photo/page-flow behavior
- Signature and Site Diagram persistence have been strengthened enough to survive the latest continuity tests

Known limitations / current truths:
- Phone/email hydration from JobTread is not yet implemented correctly in the current app flow
- The correct JobTread ownership path for phone/email still needs to be verified in code/query shape:
  - account
  - primary contact
  - location/contact relationship
  - or custom field fallback
- Do not assume arbitrary uploaded PDFs can be parsed by JobTread to populate structured fields automatically
- Not every app field will necessarily map 1:1 to a native JobTread field
- The app is still primarily local-storage based today
- Same-device continuity is the current beta target; reinstall/new-device continuity is not currently guaranteed
- Cross-device sync and multi-user shared company data remain future backend/cloud architecture work

Current architectural direction:
- JobTread is the source of truth for customer records
- The app should not create duplicate customers
- The app should not edit JobTread-owned customer master data locally unless a future phase explicitly verifies and adopts that behavior
- Linked JobTread customer/location/contact fields that come from JobTread should remain read-only in the app
- If JobTread customer/location/contact data changes upstream, the app should support refreshing those fields into the linked local scope
- The scope app should become the source of truth for:
  - scope selections
  - proposal composition
  - estimate-relevant structured output
  - customer-facing proposal/PDF generation
- PDF export should render from the app’s filtered export composition rather than raw model dumps
- JobTread integration changes should preserve offline-first behavior where possible

Immediate implementation direction:
- Audit the current JobTread hydration/query path end-to-end
- Determine where customer phone/email truly live in the JobTread graph for the linked customer flow:
  - account fields
  - primaryContact
  - related contacts
  - location/contact linkage
  - custom field fallback if needed
- Implement the smallest safe hydration expansion so phone/email populate into the linked scope when available
- Include those hydrated values in the PDF customer/header block when present
- Preserve current read-only ownership behavior for JobTread-sourced values

Most relevant near-term domains to build:
- JobTread query expansion for customer contact data
- hydration normalization for phone/email
- ownership/read-only handling for hydrated contact values
- linked-scope model mapping for phone/email
- PDF header/customer block contact rendering

Current priorities:
1. Verify the real JobTread source of phone/email for linked customers
2. Expand JobTread hydration to include phone/email safely
3. Surface hydrated phone/email in the scope UI
4. Include hydrated phone/email in the PDF header/customer block
5. Preserve current working customer search/select and address hydration behavior
6. Avoid guessing unsupported or unverified JobTread ownership paths
7. Keep this phase tightly scoped to customer contact hydration + PDF inclusion

Editing rules:
- Follow READ → PLAN → EDIT
- Make surgical edits
- Do not rewrite large files unnecessarily
- Preserve working service and model boundaries
- Explain what files changed and why
- Prefer incremental, production-safe changes over broad refactors
- Keep business logic out of low-level rendering code where possible
- This phase is JobTread customer contact hydration first, not broad feature expansion
