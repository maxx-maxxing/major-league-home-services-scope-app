Read codex_context.md before making changes.

Current working focus:
PDF export relevance filtering and export composition cleanup.

Highest-priority requirement:
When a scope is exported as a PDF, the PDF must include only information that is actually relevant to that specific scope. It should not dump every possible section/field. The export should feel intentional, concise, and professional.

Important constraint:
Do not destabilize the current working JobTread customer search/select, linked-customer hydration, verified read-only ownership behavior, Documents / Attachments section, pricing engine, returned pricing normalization/validation path, or persistence continuity fixes unless the task explicitly requires it.

Current app phase:
Release-hardening and beta continuity work have reached a reasonable stopping point for the current field beta. The next active phase is to improve PDF export behavior so the app exports only active/meaningful scope content instead of rendering everything.

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
- Signature and Site Diagram persistence have been strengthened enough to survive the latest continuity tests
- A pricing/proposal foundation layer exists
- A debug-only inspector exists for local development
- Proposal composition, pricing rule registry, config foundation, returned pricing normalization, subtotal execution, aggregate scaffolding, and selected typed lookup families exist in the pricing domain layer

Known limitations / current truths:
- The app is still primarily local-storage based today
- Same-device continuity is the current beta target; reinstall/new-device continuity is not currently guaranteed
- Cross-device sync and multi-user shared company data remain future backend/cloud architecture work
- Phone/email hydration from JobTread is still not verified from the available docs/schema and should not be assumed
- Do not assume arbitrary uploaded PDFs can be parsed by JobTread to populate structured fields automatically
- Not every app field will necessarily map 1:1 to a native JobTread field
- Final polished PDF output behavior is still under active iteration
- Current PDF export behavior is too broad and tends to include everything instead of only relevant scope content

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
from one shared structured pricing/proposal/export layer
- Pricing logic should live in a structured domain/config layer, not in SwiftUI views or the final PDF renderer
- PDF export should not render directly from the raw full scope model whenever relevance filtering is needed
- The PDF renderer should be as presentational/dumb as possible and consume a pre-filtered export composition model

Immediate implementation direction:
- Audit the current PDF export path
- Identify where the export is currently pulling/rendering too much content
- Add or strengthen an export composition/preprocessing layer that:
  - determines which sections are relevant
  - determines which rows/fields are meaningful
  - omits inactive, empty, default, or irrelevant content
- Keep export inclusion logic outside the low-level PDF drawing/rendering layer where possible
- Preserve currently relevant content in the PDF while removing noise

Most relevant near-term domains to build:
- PDF export composition model
- section inclusion rules
- field/row inclusion rules
- export filtering for inactive sections
- export filtering for empty/default values
- export handling for signatures, diagrams, attachments, and photos
- future proposal-quality PDF refinement

Current priorities:
1. Make PDF export include only relevant scope information
2. Omit inactive, empty, default, or irrelevant sections/rows
3. Keep PDF export logic maintainable by filtering before rendering
4. Preserve currently working relevant export content
5. Avoid introducing export regressions while cleaning up PDF behavior
6. Keep this phase focused on export composition/filtering, not unrelated feature work

Editing rules:
- Follow READ → PLAN → EDIT
- Make surgical edits
- Do not rewrite large files unnecessarily
- Preserve working service and model boundaries
- Explain what files changed and why
- Prefer incremental, production-safe changes over broad refactors
- Keep business logic out of low-level rendering code where possible
- This phase is export-composition first, not broad UI refactoring
