Read codex_context.md before making changes.

Current working focus:
Refining app-side data entry UX and field configuration.

Today’s likely tasks include:
- updating section options
- adding/editing dropdown values
- refining labels and field organization
- aligning form choices with real business workflow
- making small UI/data-entry improvements without disrupting the current JobTread integration flow

Important constraint:
Do not destabilize the current working JobTread customer search/select, linked-customer hydration, or verified read-only ownership behavior unless the task explicitly requires it.

Current app phase:
JobTread-first customer linking flow is working. Current focus is solidifying JobTread-owned field semantics and preparing the first safe sync-back workflow.

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
- Linked-customer hydration works for verified fields
- Street-address normalization works in tested cases
- JobTread-sourced customer fields should be treated as read-only in the app
- Refresh/re-hydration from JobTread is the intended pattern for upstream customer changes

Known limitation:
- Phone/email hydration is currently deferred because the current verified JobTread query path for those fields is not confirmed from the available docs/schema

Current architectural direction:
- JobTread is the source of truth for customer records
- The app should not create duplicate customers
- The app should not edit JobTread-owned customer master data locally
- Linked JobTread customer fields should be read-only
- If JobTread customer data changes upstream, the app should support refreshing those fields into the linked local scope
- Intended workflow:
  1. Search/select existing JobTread customer
  2. Capture scope details in the app
  3. Keep JobTread-owned customer fields read-only
  4. Refresh JobTread-owned customer fields on demand
  5. Sync relevant scope/job data back to JobTread later
  6. Support estimate/bid generation later

Current priorities:
1. Finish/polish read-only + refresh behavior for linked customer fields
2. Keep customer hydration stable and conservative
3. Do not force unsupported phone/email hydration
4. Begin the first safe one-way scope/job sync-back flow for linked scopes
5. Preserve current working search/select/hydration behavior

Editing rules:
- Follow READ → PLAN → EDIT
- Make surgical edits
- Do not rewrite large files unnecessarily
- Preserve working service and model boundaries
- Explain what files changed and why
