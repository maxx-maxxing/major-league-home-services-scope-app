# Local Backup and Restore

## User workflow

Open **Backup & Restore** from the iPad sidebar or the phone scope-list menu. Scopes confirms pending local saves before opening the sheet. Choose all local scopes or one scope, prepare the backup, then use **Save or Share Backup** to choose a destination. The app never sends it automatically. These files contain customer information, notes and original assets and are not password protected.

Choose a `.scopebackup` file from Files to validate it and review scope/file counts. Existing scope identifiers (or occupied asset folders) default to **Skip Existing**. **Keep Both** explicitly creates separate local copies with fresh scope IDs and rebased asset paths. Existing rows/files are never overwritten. JobTread references remain local metadata; restoring does not look up, create or modify JobTread customers, jobs, financial data or attachments.

## Archive contract

- This is a JSON document with base64-encoded original file bytes, not a ZIP or a copied SwiftData database. Format version **1** is independent from the authoritative field schema version **3**. Unknown format/schema versions fail closed.
- Top-level keys are `formatVersion`, `schemaVersion`, `createdAt`, `records`, `assets` and `manifestSHA256`.
- `records` mirror all 27 persisted `JobScope` members, including legacy/hidden fields, disabled measurements, document payloads, voice/AI storage contracts, IDs, dates, linked references and per-scope review marks. No persisted model shape was changed. Archive-only codecs avoid normalizing values during JSON encoding.
- `assets` contain `path`, original `data`, `sha256`, and optional `createdAt`/`modifiedAt` file attributes. Paths have the form `assets/<scope-UUID>/<relative-file-path>`. File timestamps preserve folder-discovered checklist-photo creation dates and ordering.
- All regular files in each selected `ScopeAssets/<scope-id>` folder are included, including checklist photos and deterministic PencilKit/signature/preview files without a model reference. Every explicit photo/document/sketch/signature/audio reference must resolve to an inventoried file owned by that scope. Missing/outside references stop export rather than silently omit files.
- SHA-256 covers every file. A canonical manifest checksum covers records, versions, creation date and all file paths/sizes/checksums/timestamps. Checksums detect corruption, not authenticity; strict path/version/type/size checks still apply to every imported archive.
- Limits: 1,000 scopes, 5,000 files, 32 MiB per original file, 128 MiB of original files, and 192 MiB of encoded JSON. Export one scope at a time if a library exceeds the archive limit. Inputs are read with bounded reads and `O_NOFOLLOW`, not unbounded mapped-file loads.
- Validation rejects duplicate scope/file identifiers, case/canonical-equivalent file paths, file/ancestor collisions, path traversal, unsafe components, symlinks, special files, missing references, checksums that differ, malformed/unsupported document payloads and unsupported model representations. Unknown document keys that the current native codec would discard are rejected.

## Restore and interruption safety

1. Copy the selected file into a private, marker-owned staging workspace; validate it without adding records. Pin the complete reviewed manifest so staged asset changes invalidate the preview.
2. Resolve conflicts again at application time. Prepare fresh scope IDs only when Keep Both is selected; rebase every managed reference to the destination container. Preserve within-scope asset, voice-note and draft identifiers.
3. Save and reopen the candidate metadata in a throwaway store before adoption. Fail if the current native model codec cannot preserve it exactly. This does not create a model migration plan; it prevents silently normalizing an unsupported backup.
4. Prepare asset folders privately. Persist a journal of only new destination IDs and their review marks before moving files or updating review state. Insert metadata with a separate ModelContext so rollback cannot discard the editor's unrelated work.
5. After a successful metadata save, remove the journal. On reopening, reconcile a retained journal: saved IDs retain their assets/marks; IDs absent from the store lose only their registered new folders/marks. Malformed journals or unsafe paths stop further backup work and preserve evidence.
6. A restore error discards its preview; choose the backup again for fresh conflict counts. A post-commit recovery failure may mean some scopes were restored; the error says so. Default Skip Existing remains idempotent.

Review-state writes merge the current sidecar and only locally edited section keys, preserving another window's unrelated marks and unknown future review keys. Inactive marker-owned staging workspaces are cleaned at startup; live staged previews and unmarked folders are preserved. Temporary shared export files are discarded on sheet dismissal; an interrupted process may leave exports for the OS to purge from its temporary directory.

## Validation

Run `bash scripts/verify_scope_backup.sh`. It compiles the actual model, lossless DTO, archive, review store and restore service with warnings treated as errors. Fixtures remain in sentinel-marked task directories; no installed store, network client, credentials or live JobTread service is opened.

`BackupTests/ScopeBackupSimulatorSmoke.swift` is a task-only app entry point, **not** a production source member. With `BACKUP_SIMULATOR_SMOKE`, it reuses the full synthetic matrix inside a dedicated app container and writes `Documents/BackupSmokeResults.json`, including skipped checks. It requires `ScopeBackupTests.swift` and `PersistenceFixtureValues.swift`. Never ship this test entry point or its fixture app configuration.

## Boundaries

This provides explicit local archives and fresh-install/container recovery from a valid backup. It does not provide automatic backups, encryption, cloud/company sync, authentication, damaged-store replacement, or blanket compatibility with future models. A store that cannot open still enters the existing blocked recovery screen; it is never erased automatically. Preserve that installed state and investigate separately. Physical Pencil/camera, large-library responsiveness, destination-provider interruptions, real VoiceOver and signed TestFlight validation remain release checks.
