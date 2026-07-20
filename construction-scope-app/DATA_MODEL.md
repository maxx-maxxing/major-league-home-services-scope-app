# DATA_MODEL.md

## Source of Truth
`schema.json` is authoritative. Swift models should match it (enums + fields).

## Primary Entity: JobScope
High-level:
- identity + timestamps + status
- section sub-models (project info, enclosure, attachments, etc.)
- optional photos + sketches
- customer approval (signature)

## Persistence
- Offline-first local persistence (SwiftData preferred; CoreData acceptable).
- Autosave on edits with debounced writes.
- Jobs are created from a locked template default set; the template is not editable.

## Notes on Input
- Use enums wherever possible to reduce typing.
- Keep required fields minimal; enforce missing fields only at export/preview time.
- Existing Conditions stores `existingStructure` selections separately from optional `existingStructureNotes` so structure-specific notes persist without mixing into general Field Notes.
- Screen Enclosure stores current type choices in `enclosureTypes`; retired sunroom/window enclosure values remain decode-compatible but are not current selectable options.
- Screen Enclosure stores optional `screenEnclosureNotes` separately from Sunroom/window notes.

## SwiftData Evolution Policy
- The current persisted root is `JobScope`; its stored properties and every nested `Codable` type they reference are part of the on-device persistence contract.
- Treat these changes as migration-sensitive:
  - adding a stored property, even when optional
  - renaming or removing a stored property
  - changing a property's type or optionality
  - changing enum raw values
  - changing the stored shape of a nested `Codable` value
  - changing the encoding contract of `documentsPayload`
- Additive optional fields may be lightweight-migratable, but that is a hypothesis until the baseline-to-candidate compatibility gate passes.
- Renames, removals, type changes, optional-to-required changes, and incompatible nested-value changes are blocked from beta release until an explicit `VersionedSchema` / `SchemaMigrationPlan`, store-compatible representation repair, or reviewed file-backed/versioned sidecar strategy exists.
- Do not advance a compatibility baseline merely to make a failing test pass. Advance it only after that exact build is identified as a known-good installed/release baseline and its continuity evidence is recorded.
- Keep app-owned assets outside SwiftData when practical, but remember that stored absolute paths do not provide reinstall/new-container recovery.

## Persistence Compatibility Gate
- Repository baseline commit: `07b42f308cee328926046f3198bbaa5fe36fa43b`.
- Run `./scripts/verify_persistence_compatibility.sh` for the current additive `voiceNotes` / `aiExtractionDrafts` candidate and whenever that candidate changes.
- Do not treat the current fixture as blanket proof for a later persisted-shape change. Before changing another `JobScope` property, nested `Codable`, enum raw value, or encoded payload, first extend the fixture to populate and assert the affected branch or add a purpose-built migration test.
- The gate:
  - reconstructs and compiles the pinned baseline model source with the current host Xcode/SwiftData toolchain
  - checks that the authoritative `schema.json` declares the candidate AI arrays and referenced types while the pinned baseline does not
  - creates a sanitized baseline SwiftData store with representative scope, JobTread-reference, document, photo, signature, and sketch metadata
  - opens that store with the working-tree model
  - verifies every populated baseline root value and asset-metadata value survives and new optional AI fields initially resolve to `nil`
  - saves deterministic values for every current voice-note, draft, and nested-suggestion field and verifies the full values survive a separate reopen
  - rejects store paths outside its sentinel-marked `/tmp` directory, deletes sanitized artifacts after success, and retains a pristine baseline plus failure evidence on failure
- This is a host-reconstructed source-delta smoke test. It is not a store emitted by the historical iOS app/toolchain, does not exercise an iOS application update, and does not replace SwiftData `VersionedSchema` / `SchemaMigrationPlan` work.
- `schema.json` is contract documentation, not a SwiftData migration engine. Its current integer version does not establish an on-device migration path; the gate checks candidate declaration parity but validates runtime behavior against `SchemaModels.swift`.
- The actual build installed on a field device is currently unknown and must not be inferred from the pinned commit.
- Before TestFlight handoff, also perform an update-in-place device test without uninstalling: preserve the test container, install candidate B over known build A, force-close/relaunch, and verify representative fields plus every asset category and PDF export.
- A compatibility-gate failure blocks the candidate. Investigate the retained sanitized directory reported by the script; never delete/recreate a user's store as an automatic migration strategy.
