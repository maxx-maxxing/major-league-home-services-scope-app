# DOCUMENTATION.md
# Project Log - Construction Scope App

## Current Status
- Milestone 0: Implemented
- Milestone 1: Implemented
- Milestone 2: Implemented (requested section editors)
- Milestone 2.1: Implemented (Windows & Glass stability/usability pass)
- Milestone 3: Implemented (PencilKit signature + sketch capture)
- Milestone 4+: Not started

## Decisions
- SwiftData remains the persistence layer (`JobScope` model + Codable value types).
- Milestone 2 section editors implemented for:
  - Project Info
  - Enclosure
  - Windows & Glass
  - Attachment Conditions
  - Production Notes
- UI follows first-party system style from `UI_SYSTEM.md`:
  - card groups (`.regularMaterial`)
  - grouped system background
  - semantic typography only
  - 44pt+ tap targets
- Progressive disclosure is used to keep forms compact:
  - dependent fields appear only when toggles/pickers enable them
  - examples: custom colors, trim details, production metadata, start date, notes blocks
- Inputs follow native control guidance:
  - Picker / Toggle / Segmented controls for discrete options
  - TextEditor for notes (Scribble-friendly)
- Milestone 2.1 Windows & Glass fixes:
  - `Window Type` and `Glass Type` now support `Not Set` to restore schema-optional (`nil`) state.
  - Empty `windowSystem` is now cleaned up to `nil` instead of persisting an all-empty nested object.
  - Empty `enclosure` is now cleaned up to `nil` when no enclosure data remains.
- Milestone 3 Pencil support:
  - `Signature & Export` section now renders a dedicated PencilKit editor (replacing placeholder stub view in that section).
  - Customer signature is captured and persisted:
    - PNG preview path -> `customerApproval.signaturePNGPath`
    - Signed date -> `customerApproval.signedDate` (defaults on first signature)
  - Salesperson signature is captured and persisted as a `SketchAttachment` titled `Salesperson Signature`.
  - Optional site diagram is captured and persisted as a `SketchAttachment` titled `Site Diagram`.
  - Drawing data (`.drawing`) and PNG previews are stored in app Application Support under `ScopeAssets/<scope-id>/`.
- Production notes are stored in `customerApproval.optionsConfirmedText` (schema-consistent text field already available).
- `schema.json` was not changed.

## How to Run
1. Open [ConstructionScopeApp.xcodeproj](/C:/Users/your_/Downloads/construction-scope-app_coderpack_plus/construction-scope-app/ConstructionScopeApp.xcodeproj).
2. Select the `ConstructionScopeApp` scheme.
3. Choose an iPhone or iPad simulator (iOS 17+).
4. Build and Run (`Cmd+R`).

## How to Demo (Smoke Test)
1. Tap/click `New Scope`.
2. Open and edit:
   - `Project Information`
   - `Enclosure`
   - `Windows & Glass`
   - `Attachment Conditions`
   - `Production Notes`
3. Wait briefly for autosave debounce (~0.8s).
4. Relaunch the app and verify edits persist.
5. In `Windows & Glass`, toggle `Configure Window System` on/off and verify empty data does not persist.
6. Set `Window Type` and `Glass Type`, then reset each to `Not Set` and verify values clear after autosave + relaunch.
7. Open `Signature & Export`, draw customer and salesperson signatures, and add a site diagram.
8. Wait for autosave debounce (~0.8s), relaunch app, and verify all drawings restore.
9. Clear each drawing and verify related stored model fields clear after autosave + relaunch.

## Known Issues / Follow-ups
- Remaining section editors are still placeholders.
- PDF preview/export is still stubbed (Milestone 4).
- Customer signature uses `customerApproval` schema fields directly; salesperson signature is currently stored as a sketch attachment because schema does not yet include a dedicated salesperson-signature field.
- Runtime Pencil interaction still needs on-device/manual verification in simulator or hardware (build validation completed with `xcodebuild` on March 9, 2026).
