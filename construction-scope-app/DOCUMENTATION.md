# DOCUMENTATION.md
# Project Log - Construction Scope App

## Current Status
- Milestone 0: Implemented
- Milestone 1: Implemented
- Milestone 2: Implemented (requested section editors)
- Milestone 2.1: Implemented (Windows & Glass stability/usability pass)
- Milestone 2.2: Implemented (remaining schema-backed section editors)
- Milestone 3: Implemented (PencilKit signature + sketch capture)
- Milestone 4: Implemented (flattened PDF preview + export)
- Milestone 5: Not started
- Milestone 6: Implemented (photo attachment flow + PDF photo appendix)
- Milestone 7.1: In progress (interaction animation polish)

## Decisions
- SwiftData remains the persistence layer (`JobScope` model + Codable value types).
- Milestone 2 section editors implemented for:
  - Project Info
  - Existing Conditions
  - Dimensions
  - Structural System
  - Enclosure
  - Windows & Glass
  - Electrical
  - Drainage
  - Attachment Conditions
  - Finishes
  - Permits / HOA
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
- Milestone 2.2 remaining section editor implementation:
  - Added native SwiftUI editors for:
    - `Existing Conditions`
    - `Dimensions`
    - `Structural System`
    - `Electrical`
    - `Drainage`
    - `Finishes`
    - `Permits / HOA`
  - Added shared editor helpers for:
    - Scribble-friendly note cards (`TextEditor`)
    - numeric measurement fields
    - optional yes/no/not-set segmented controls
  - New section editors now clean empty nested values back to `nil` for:
    - `existingConditions`
    - `photoChecklist`
    - `dimensions`
    - `structuralSystem`
    - `electrical`
    - `drainage`
    - `finishes`
    - `permitsHOA`
  - Placeholder section routing was removed; all sections in the current sidebar now open real editors.
- Milestone 3 Pencil support:
  - `Signature & Export` section now renders a dedicated PencilKit editor (replacing placeholder stub view in that section).
  - Customer signature is captured and persisted:
    - PNG preview path -> `customerApproval.signaturePNGPath`
    - Signed date -> `customerApproval.signedDate` (defaults on first signature)
  - Salesperson signature is captured and persisted as a `SketchAttachment` titled `Salesperson Signature`.
  - Optional site diagram is captured and persisted as a `SketchAttachment` titled `Site Diagram`.
  - Drawing data (`.drawing`) and PNG previews are stored in app Application Support under `ScopeAssets/<scope-id>/`.
- Milestone 4 PDF/export implementation:
  - Added CoreGraphics-based PDF renderer (`UIGraphicsPDFRenderer`) for flattened PDF output.
  - Added native preview sheet using PDFKit (`PDFView`) and toolbar `Preview` action wiring.
  - Added toolbar `Export` action wiring via iOS share sheet (`UIActivityViewController`).
  - Rendered output includes:
    - Header: client, address, project type, optional job number
    - Footer: generated date/time and page X of Y
    - Five core content pages based on `PDF_EXPORT.md` outline
    - Customer signature image + signed date when present
    - Optional site diagram appendix page when present
  - Added missing-required-field checks (currently client name + address) surfaced in preview.
  - Export filename now follows a sanitized convention:
    - `{ClientLastToken}-{AddressNoSpaces}-{ProjectType}-Scope.pdf`
- Milestone 4.6 expanded PDF coverage:
  - Extended PDF summaries to include newly implemented editor data for:
    - project city/ZIP, estimator, and site visit date
    - dimensions attachment type + elevation notes
    - HOA notes + photo checklist summary
    - attachment detail summaries for custom materials, post spacing, trim, and fastener plan
    - enclosure custom frame colors, knee wall details, and door notes
    - window grid/operation/color/height/bay details
    - electrical switch locations, dedicated circuits, and notes
    - drainage downspout locations
    - finishes section on page 5
    - permit status notes + production material/permit statuses
  - Preserved the current five-page PDF layout from `PDF_EXPORT.md`.
- Milestone 6 photo attachment support:
  - Added a native toolbar-driven photo management sheet using `PhotosPicker`.
  - Imported photos are stored locally under the scope asset directory and persisted in `scope.photos`.
  - Photo captions can be edited after import and individual photos can be deleted.
  - The PDF appendix now adds one page per stored photo with caption + created timestamp.
- Milestone 7.1 interaction polish:
  - Added animated new-scope creation/deposit feedback in the sidebar.
  - Added animated scope row deletion transitions in scope lists.
  - Added animated scope selection changes in the sidebar.
  - Added animated section switching transitions in the iPad detail pane.
  - Added animated folder disclosure expand/collapse behavior in the sidebar.
  - Added consistent reveal/collapse motion for progressive-disclosure form content:
    - site visit date
    - enclosure screen/knee-wall/door options
    - window-system configuration blocks
    - attachment custom-material/trim fields
    - production schedule metadata and notes
    - signed-date controls in signature capture
  - Added subtle content transitions for editor header text and status-pill changes.
  - Added toolbar action feedback for preview/export/photos controls in the editor.
  - Added animated photo import/delete transitions inside the photo-management sheet.
  - Added animated clear-state feedback for signature and site-diagram reset actions.
  - Native sheet presentations for preview/photos/share remain system-driven; additional custom presentation polish can be layered on if needed after runtime review.
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
10. Tap toolbar `Preview` and verify the PDF loads with section pages and (if available) missing required field warnings.
11. Tap toolbar `Export` and verify share sheet opens with generated PDF file.
12. Verify generated PDF shows header/footer and customer signature/date when signature exists.
13. Tap toolbar `Photos`, import one or more photos from the photo library, add captions, and verify they persist after relaunch.
14. Reopen `Preview` and verify imported photos appear as appendix pages in the PDF.

## Known Issues / Follow-ups
- Customer signature uses `customerApproval` schema fields directly; salesperson signature is currently stored as a sketch attachment because schema does not yet include a dedicated salesperson-signature field.
- PDF rendering currently uses deterministic text blocks rather than full visual chips/checkmark treatments from design aspirational notes.
- Full interactive walkthroughs are still needed for every newly added editor and the PDF preview/export flow on simulator/device.
- Full manual runtime verification is still needed for actual photo-library import on device/simulator UI interaction.
- Unsandboxed `xcodebuild` validation succeeded on March 10, 2026 using:
  - `xcodebuild -project ConstructionScopeApp.xcodeproj -scheme ConstructionScopeApp -destination 'generic/platform=iOS' -derivedDataPath /tmp/ConstructionScopeAppDerived CODE_SIGNING_ALLOWED=NO build`
- Simulator runtime validation on March 10, 2026:
  - built for `iPad Pro 11-inch (M5)` simulator
  - installed successfully with `simctl`
  - launched successfully with bundle id `com.example.ConstructionScopeApp`
  - initial split-view UI rendered correctly on launch
- PDF coverage validation on March 10, 2026:
  - simulator build succeeded after expanding page mappings
  - export/preview compile path remains healthy
- Photo flow validation on March 10, 2026:
  - simulator build succeeded after adding `PhotosPicker` flow and photo appendix pages
- Current build warnings are limited to:
  - AppIntents metadata extraction skipped because the app does not link `AppIntents.framework`
