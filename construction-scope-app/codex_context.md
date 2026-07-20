Read codex_context.md before making changes.

Current working focus:
Production readiness through persistence compatibility, release validation, and feature-preserving cleanup.

Highest-priority requirement:
Do not ship another persisted-shape change until its repository-baseline compatibility gate passes and the exact installed TestFlight baseline is identified for an update-in-place device test.

Important constraint:
Do not destabilize the current working JobTread customer search/select, linked-customer hydration, verified read-only ownership behavior, Documents / Attachments section, pricing engine, persistence continuity fixes, current PDF export improvements, or current section review/completion workflow unless the task explicitly requires it.

Current app phase:
Milestone 7.6.3 persistence schema discipline is active. Milestone 7.6.3.1 is implemented with a standalone host compatibility gate and policy without runtime app changes. The installed-build device continuity gate remains manual, and Milestone 7.6.4 backup/recovery remains a later, separately approved feature milestone.

What is already true:
- SwiftUI iPad construction scope app exists
- Core section-based workflow exists
- Offline-first behavior remains important
- JobTread connectivity has been verified
- Scope naming has been separated from customer identity
- JobTread customer search/select creation path exists
- Live partial-name JobTread customer search works
- Selecting a JobTread customer creates a linked scope
- Linked-customer hydration works for verified fields and has recently been strengthened for phone/email
- Verified JobTread-sourced customer fields are treated as read-only in the app
- Current PDF export now includes only relevant scope content and has improved layout/thumbnail behavior
- Signature and Site Diagram persistence have been strengthened enough to survive recent continuity tests
- Section review/completion workflow exists
- Project-type-driven section visibility is implemented for iPad and compact navigation
- Hidden sections preserve their stored data and are excluded from PDF/proposal composition while hidden
- Release JobTread credentials and sensitive diagnostics are contained by Milestone 7.6.2.2
- Store-open failure blocks editing behind the recovery screen instead of silently replacing the persisted store
- The host-reconstructed repository-baseline persistence smoke test verifies the current additive AI storage candidate against commit `07b42f308cee328926046f3198bbaa5fe36fa43b`

Known limitations / current truths:
- The actual build/commit installed on the field TestFlight device is unknown
- There is no `VersionedSchema` or `SchemaMigrationPlan`
- The current working tree adds optional `voiceNotes` and `aiExtractionDrafts` directly to `JobScope`; current-host source-delta compatibility is testable, but original-iOS-build and installed-build compatibility still require a device update test
- `documentsPayload` is an encoded blob and remains migration-sensitive
- Asset metadata stores absolute local paths, so reinstall/new-container recovery is not supported
- There is no lossless scope backup/import package yet; flattened PDF export is not a data restore format
- Release JobTread lookup/refresh is intentionally unavailable until an authenticated distributed-read boundary is approved
- Signed TestFlight UI smoke testing and build-A → build-B continuity testing remain manual release gates

Current architectural direction:
- Preserve the current offline-first SwiftData model and app-owned asset layout while compatibility evidence is established
- Treat every `JobScope` property and nested stored `Codable` shape as a persistence contract
- Require the standalone baseline-to-current gate for the current AI storage candidate; extend it or add a purpose-built migration test before any different stored-shape change
- Block renames, removals, type changes, enum raw-value changes, optional-to-required changes, and incompatible nested-shape changes until an explicit migration or reviewed sidecar strategy exists
- Never advance the pinned baseline merely to make a failing test pass
- Keep runtime features unchanged during Milestone 7.6.3.1
- Design lossless backup/import only as a separate Milestone 7.6.4 slice with relative asset paths, validation, and atomic import

Immediate implementation direction:
- Keep `SchemaModels.swift` and `schema.json` frozen during the compatibility-gate slice
- Preserve the passing `./scripts/verify_persistence_compatibility.sh` result for the current candidate
- Preserve the passing Debug/Release builds, Release analysis, JobTread security gate, plist/project validation, and whitespace checks
- Treat the automated result as a current-host source-delta smoke test, not historical-iOS or field-device upgrade proof
- Identify the exact installed TestFlight build before claiming field-device upgrade safety
- Execute the documented update-in-place continuity matrix before field handoff
- Stop before backup/import implementation, explicit migrations, TestFlight deployment, grant rotation, commit, or push

Current priorities:
1. Preserve all currently working features and stored data
2. Prove repository-baseline → current-candidate SwiftData compatibility
3. Identify and test the actual installed TestFlight baseline
4. Freeze unreviewed persistence-shape changes
5. Add lossless local backup/import in a later approved milestone
6. Restore distributed JobTread reads only behind an approved authenticated boundary

Editing rules:
- Follow READ → PLAN → EDIT
- Make surgical edits
- Do not rewrite large files unnecessarily
- Preserve working service and model boundaries
- Explain what files changed and why
- Prefer incremental, production-safe changes over broad refactors
- Keep business logic out of low-level rendering code where possible
- Do not commit or push until the user has tested and explicitly approves Git operations
