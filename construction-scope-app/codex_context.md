Read `codex_context.md` before making changes.

Current working focus:
Milestones 7.6.4.1 save-failure containment, 4.8.4 PDF diagnostic privacy, 7.6.2.3 offline JobTread customer read-contract verification, and 7.6.4.2 save-confirmed Documents asset retirement are implemented and repository-verified. Preserve these checkpoints. The next queued feature-preserving candidate is Documents async-import concurrency safety; scope immutable request identity, stale-completion rejection, and never-adopted file cleanup separately without broadening into backup/import, path migration, or unrelated asset systems.

Git checkpoint and authority:
- Active branch: `ai-scope-assistant`
- Verified checkpoints `4b6bce0` (Release/compatibility), `2f544e7` (save containment/roadmap), `366b090` (PDF diagnostics), and `95a9978` (offline JobTread read contract) are pushed to `origin/ai-scope-assistant`. Milestone 7.6.4.2 is the current verified bounded checkpoint; confirm `HEAD` and upstream before beginning another slice.
- The user has authorized commit/push for bounded, verified hardening work.
- That authority does not include a pull request, merge, deployment/TestFlight upload, credential rotation, backend/cloud creation, or live JobTread write/sync.
- Verify and report each new bounded slice before treating it as complete; do not fold unrelated working-tree changes into a commit.

Highest-priority requirement:
Preserve all verified privacy/durability boundaries: covered Release save failures must continue to show and retry through the persistence-health warning; PDF diagnostics must exclude raw customer-entered or identifying content, persistent scope IDs, filenames, paths, user labels/text, and raw dynamic contexts; and the standalone JobTread customer contract gate must remain synthetic, offline-only, and outside the app target. Reviewed aggregate numeric/boolean PDF metrics remain permitted.

Current roadmap position:
- `PLANS.md` contains the authoritative audited roadmap ledger dated 2026-07-20.
- Milestones 0–4 are implemented in code; physical-device PDF validation remains a release gate.
- Milestone 4.8.4 removes customer-/scope-derived PDF diagnostic content while preserving export behavior; representative target-device PDF/filename comparison remains manual.
- Milestone 5 is partial: Debug customer read/link/refresh and internal sample/draft proposal-pricing scaffolding exist. Release authentication and every outbound JobTread write/sync remain unimplemented.
- Milestone 7.6.2.3 pins the current Debug customer search/detail encoder, decoder, fallback, and privacy contracts against a synthetic offline transport; it does not prove live Pave behavior or scope-model hydration.
- Milestone 5.6.1 is optional voice-note/AI-draft storage only; no AI capture or generation feature exists.
- Milestone 7.2 acceptance closeout remains open.
- Milestone 7.6.3 is an active persistence-shape guardrail; 7.6.3.1 host-reconstructed compatibility testing is implemented, while installed-build device continuity remains manual.
- Milestone 7.6.4 remains in progress: 7.6.4.1 and 7.6.4.2 are implemented, while async Documents import concurrency, the device continuity matrix, and lossless backup/import remain separate open work.

Important feature-preservation constraint:
Do not destabilize the current JobTread customer search/select and linked-customer hydration, verified read-only ownership behavior, Documents / Attachments section, pricing engine/scaffolding, persistence continuity fixes, PDF export improvements, section review/completion workflow, project-type-driven visibility, section-scoped measurements, signature capture, or site-diagram flow unless the task explicitly requires it.

What is already true:
- SwiftUI iPad/compact construction-scope workflows and offline-first SwiftData storage exist.
- Scope naming is separate from linked customer identity.
- Debug JobTread customer search/select, verified hydration, and refresh work for the currently supported fields.
- Release direct JobTread access and sensitive diagnostics are contained; distributed lookup/refresh is intentionally unavailable until an approved authenticated boundary exists.
- Store-open failure blocks editing behind a recovery screen instead of silently substituting a new persisted store.
- Documents use an app-controlled encoded payload. Superseded Documents files retire only after a confirmed metadata save through a scope/attachment-bound, symlink-safe path; app-owned files also back photos, sketches, and signatures through their existing systems.
- PDF preview/export, contextual section visibility, section review state, and section-scoped measurements are implemented.
- The repository-baseline persistence harness verifies the current additive AI storage candidate against baseline commit `07b42f308cee328926046f3198bbaa5fe36fa43b` using the current host toolchain.

Known limitations and manual gates:
- The exact build/commit installed on the field TestFlight device is still unknown.
- There is no `VersionedSchema` or `SchemaMigrationPlan`.
- The host-reconstructed compatibility result is not proof of an original historical iOS-store upgrade or the installed field-device update path.
- `documentsPayload` remains an opaque encoded persistence boundary.
- Asset metadata uses absolute app-container paths; reinstall/new-container recovery is unsupported.
- Documents retirement actions are in-memory and fail safe toward orphan retention; there is no durable retirement ledger or orphan sweep.
- Documents async imports are not yet request-tokened or cancellation-aware; late/out-of-order completion and never-adopted file cleanup remain the next bounded concurrency candidate.
- There is no lossless scope backup/import package or cross-device/company sync.
- Signed TestFlight launch/UI smoke testing, build-A → update-in-place-to-B continuity, physical-device PDF/documents checks, Dynamic Type, VoiceOver, Reduce Motion, and Light/Dark acceptance remain manual release gates.

Milestone 7.6.4.1 verified boundary:
- Cover debounced autosave/manual flush plus scope create, rename, delete, access-time, linked-customer hydration, and linked-customer refresh saves.
- Preserve the existing debounce interval, timestamp updates, and happy-path behavior.
- Keep warning and diagnostic content generic and privacy-safe; do not surface/log raw errors, customer data, IDs, credentials, queries, or local paths.
- Add narrow injected failure/retry verification and run proportional Debug/Release build, Release analysis, persistence compatibility, JobTread security, project/plist, script, and whitespace gates.
- Keep `SchemaModels.swift` and `schema.json` byte-for-byte unchanged in this slice.
- Exclude migrations, store deletion/recreation, rollback, backup/import, asset-path redesign, JobTread behavior changes, pricing/PDF redesign, deployment, and all live-system mutations.
- Repository verification passed for injected failure/retry behavior, exact save routing and privacy checks, Debug/Release builds, Release analysis, persistence compatibility, JobTread security, project/plist parsing, shell syntax/modes, and whitespace.
- Manual acceptance still covers target-device warning layout/hit testing across presentations, retained-warning visibility after Apple-owned photo/file/camera pickers dismiss, VoiceOver, Dynamic Type, Reduce Motion, Light/Dark, background/foreground, force-close/relaunch, and signed build continuity.

Milestone 7.6.4.2 verified boundary:
- Replace, clear, and additional-row deletion update visible Documents metadata first and retire the old file only after the shared model-context save succeeds; failed attempts/retries retain the cleanup action and old file.
- Operations that supersede an existing file use the existing immediate manual-flush path. Metadata-only edits and rows without an attachment retain the existing debounce behavior.
- Before cleanup, recheck the current scope for the old ID or standardized path. Retirement must remain bound to the exact current `Application Support/ScopeAssets/<scope-id>/Documents` directory and attachment-ID filename prefix.
- Preserve `openat`/`fstatat`/`unlinkat`, `O_NOFOLLOW`, `AT_SYMLINK_NOFOLLOW`, regular-file-only deletion, fixed path-free outcomes, and fail-safe orphan retention.
- `./scripts/verify_document_asset_retirement.sh` must pass alongside save-health, compatibility, JobTread contract/security, and PDF privacy gates. The model/schema freeze remains byte-for-byte unchanged.
- Manual acceptance still requires target-device Files/Photos/Camera replace, clear, and row-delete flows; injected failure/retry; force-close/relaunch; current/new file reopening; and perceived responsiveness of the immediate destructive-save boundary.
- Exclude async import request-token/task cancellation work, durable cleanup ledgers/sweeps, relative-path migration, backup/import, reinstall recovery, other asset systems, deployment, and external writes from maintenance of this checkpoint.

Milestone 4.8.4 verified boundary:
- PDF logger calls use fixed events plus an exact allowlist of numeric/boolean metrics only.
- Persistent scope IDs, customer-derived filenames, paths, page/section/row labels, rendered text contexts, and raw dynamic summaries remain excluded from diagnostics.
- Keep customer-facing filename generation, PDF composition/layout/pagination, preview/share, and user-visible errors unchanged.
- `./scripts/verify_pdf_export_privacy.sh` must pass alongside the existing save-health, compatibility, and JobTread security gates.
- Manual acceptance still requires representative target-device PDF content/layout and share-sheet filename comparison.

Milestone 7.6.2.3 verified boundary:
- `./scripts/verify_jobtread_read_contract.sh` compiles the real Debug config/client into a standalone executable and routes every request through an unconditional test-only `URLProtocol` using a reserved `.invalid` endpoint.
- Preserve whitespace short-circuiting; prefix `like`, contains `like`, then exact `=` fallback; customer-only filters; current sizes/selections; client-detail primary/fallback mapping; count-only API errors; and HTTP status classification.
- Keep fixtures synthetic and failure output fixed/privacy-safe. Never read local credentials, use `URLSession.shared`, permit network fallthrough, add the harness to the app target, or make a live JobTread call.
- The gate pins the reviewed client/config, model/schema, and project hashes. Any intentional change to those files requires contract review and a deliberate hash/test update rather than bypassing the gate.
- Do not overclaim: `fetchCurrentGrant`, scope-model `applyLinkedCustomerHydration`, live vendor-schema compatibility, retries/backoff, and Release authentication are outside this milestone.

Persistence discipline:
- Treat every `JobScope` property and nested stored `Codable` shape as a persistence contract.
- Do not rename/remove stored fields, change types or enum raw values, make optional fields required, or change nested encoded shapes without an explicit reviewed migration/compatibility strategy.
- Never advance the pinned compatibility baseline merely to make a failing gate pass.
- Identify and validate the actual installed TestFlight baseline before claiming field-device upgrade safety.

Editing rules:
- Follow READ → PLAN → EDIT.
- Make surgical, testable changes and preserve unrelated user work.
- Keep business logic out of rendering code where practical.
- Update `PLANS.md`, `DOCUMENTATION.md`, and this context when roadmap status, behavior, verification, or release gates materially change.
- Report files changed, verification results, remaining risks, and required manual checks.
