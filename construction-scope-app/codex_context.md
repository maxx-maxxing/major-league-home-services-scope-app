Read codex_context.md before making changes.

Current app phase:
JobTread-first workflow implementation is now working end-to-end at the customer selection level. Current focus is locking down JobTread-owned data semantics and refresh behavior.

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
- JobTread customer search/select creation path exists
- Live partial-name JobTread customer search works
- Selecting a JobTread customer creates a linked scope
- Selected-customer hydration populates customer/project fields
- Street-address normalization is working in tested cases

Current architectural direction:
- JobTread is the source of truth for customer records
- The app should not create duplicate customers
- JobTread-sourced customer fields should be treated as read-only in the app
- If JobTread data changes upstream, the app should support a refresh/sync action to rehydrate those fields into the local scope
- Intended workflow:
  1. Search/select existing JobTread customer
  2. Capture scope details in the app
  3. Keep JobTread-owned customer data read-only
  4. Allow refresh from JobTread for linked customer fields
  5. Sync relevant scope/job data back to JobTread later
  6. Support estimate/bid generation later

Current priorities:
1. Make JobTread-owned linked customer fields read-only in the app
2. Add a "Refresh from JobTread" / similar action for linked customer data
3. Preserve editability for local scope-owned fields only
4. Keep search/select and hydration flow stable
5. Implement outbound sync only after read-only/refresh semantics are solid

Editing rules:
- Follow READ → PLAN → EDIT
- Make surgical edits
- Do not rewrite large files unnecessarily
- Preserve working service and model boundaries
- Explain what files changed and why
