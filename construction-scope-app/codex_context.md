Read codex_context.md before making changes.

Current app phase:
JobTread-first workflow implementation and refinement.

What is already true:
- SwiftUI iPad construction scope app exists
- Core section-based workflow exists
- Offline-first behavior remains important
- PDF export remains flattened by default
- JobTread connectivity has been verified
- The app has additive model support for:
  - scopeTitle
  - jobTreadCustomer
  - jobTreadJob
  - jobTreadSync
- Scope naming has been separated from customer identity
- A JobTread customer search/select creation path exists
- Exact full-name JobTread customer lookup currently works
- Selecting a matching JobTread customer creates a linked scope
- Current seeded customer data is intentionally minimal/safe

Current architectural direction:
- JobTread is the source of truth for customer records
- The app should not create duplicate customers
- Intended workflow:
  1. Search/select existing JobTread customer
  2. Capture scope details in the app
  3. Sync relevant scope/job data back to JobTread
  4. Support estimate/bid generation later

Current priorities:
1. Improve JobTread customer search from exact full-name match to practical partial-name lookup
2. Refine the customer selection UX, likely toward live/typeahead results
3. Hydrate additional selected-customer details through doc-supported follow-up queries
4. Preserve compatibility with current forms/PDF flow while reducing transitional field dependence
5. Implement sync back to JobTread only after customer lookup/selection is solid

Editing rules:
- Follow READ → PLAN → EDIT
- Make surgical edits
- Do not rewrite large files unnecessarily
- Preserve working service and model boundaries
- Explain what files changed and why
