# DOCUMENTATION.md
# Project Log - Construction Scope App

## Current Status
- Milestone 0: Implemented
- Milestone 1: Implemented
- Milestone 2: Implemented (requested section editors)
- Milestone 2.1: Implemented (Windows & Glass stability/usability pass)
- Milestone 3+: Not started

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

## Known Issues / Follow-ups
- Remaining section editors are still placeholders.
- Signature capture and sketch are not implemented yet (Milestone 3).
- PDF preview/export is still stubbed (Milestone 4).
- Build/runtime validation could not be executed in this environment because Xcode tooling (`xcodebuild`) is unavailable on this machine.
