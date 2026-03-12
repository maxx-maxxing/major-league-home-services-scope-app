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
- Milestone 7.2: In progress (acceptance closeout)
- Milestone 7.3: In progress (liquid-glass chrome pass)
- Milestone 7.4: In progress (maximalist Liquid Glass exploration)

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
- Milestone 7.2 acceptance closeout pass:
  - The toolbar `Sketch` action is no longer a dead control:
    - on iPad split view it now routes to the `Signature & Export` section
    - on compact navigation it opens a dedicated `Sketch Tools` sheet
  - Added accessibility improvements for custom navigation controls:
    - `New Scope` row now exposes an explicit label + hint
    - selected scope rows now expose combined labels/selection state
    - section rows now expose selection state to VoiceOver
    - toolbar preview/export/photos/sketch buttons now expose clearer hints
- Milestone 7.3 liquid-glass chrome pass:
  - Work is isolated on branch:
    - `feature/liquid-glass-chrome-pass`
  - Added a restrained chrome-specific material style for:
    - top summary/header surfaces
    - overlay/modal cards
    - toolbar action icons
    - preview/photo shell surfaces
  - Core form cards and field entry surfaces remain on the existing practical styling to preserve scanability and form usability
  - Updated status-pill treatment to feel more layered without changing underlying information density
  - Follow-up refinement pass:
    - removed the redundant sidebar `Current Scope` section heading above the floating summary card
    - strengthened section-group separation by adding more distinct highlight/stroke/shadow treatment to `CardGroup`
    - reduced material heaviness slightly so chrome and section cards read more translucent
- Milestone 7.4 maximalist Liquid Glass exploration:
  - Pushed the design intentionally beyond the restrained pass to establish the upper bound of the aesthetic
  - Added a stronger full-screen luminous glass backdrop and broader translucency across:
    - root navigation/editor shells
    - preview and photo-management screens
    - section cards
    - project-info text-entry surfaces
    - notes areas
    - segmented yes/no control groups
    - floating status and toolbar action treatments
  - Added code comments around the main experimental Liquid Glass decisions so the branch can be scaled back later
  - Follow-up maximalist pass:
    - regrouped top action controls into floating glass toolbar clusters instead of isolated buttons
    - centralized the text-entry glass treatment in shared components so text fields and Scribble-friendly text areas stay visually consistent
    - applied the unified glass input treatment to overlays, photo captions, and additional section-editor text fields
  - Consistency sweep:
    - added a shared non-text `liquidGlassSurface()` modifier for utility surfaces that should match the branch chrome without pretending to be text inputs
    - applied the shared surface treatment to the PencilKit drawing canvas container and the empty photo preview placeholder
  - Full compliance sweep:
    - rebalanced the luminous backdrop and shared glass primitives away from blue-tinted decorative blur and toward neutral Apple-style pooled glass
    - tightened sidebar scope/section selection so highlighted rows read as integrated glass selection states rather than isolated stickers
    - regrouped editor toolbar actions as a cohesive system-host control group without reintroducing a custom floating top-bar capsule
    - upgraded rename overlays, compact navigation shells, photo/PDF sheets, and drawing/image utility surfaces to use the same glass language and calmer sheet hierarchy
    - refined helper controls such as segmented optional pickers and note surfaces so they no longer fall back to generic blur tiles
  - Apple-correctness refinement pass:
    - softened sidebar and scope selection so navigation emphasis feels more native to the sidebar layer and less like separate floating cards
    - differentiated chrome panels from routine content cards and inputs so not every surface carries the same visual weight
    - reduced shadow dependence across shared surfaces and let the material/highlight system carry more of the hierarchy
    - kept the monochrome palette, spacing rhythm, semantic pills, and system-toolbar-host top chrome intact
  - Narrow refinement pass:
    - replaced chip-like sidebar selection with integrated row emphasis using a slim accent rail, softer pooled material, and no floating checkmark treatment
    - increased separation between the editor header chrome and the card stack below by calming `CardGroup` while giving the header a clearer chrome identity
    - restored a restrained Liquid Glass read to inputs and utility containers through light tint/highlight layering instead of thicker borders or stronger shadows
  - Schema/UI field alignment pass:
    - updated the enclosure type taxonomy to use `Screen Enclosure` in place of the previous split `Screen Only` / `Screen Room With Door` choices
    - added notes fields for `Structural System` and `Windows & Glass` in the schema-backed model, editors, and PDF summary
    - expanded schema-backed dropdown enums used by section editors so each menu includes an `Other` option
    - refined `Knee Wall + Doors` so aluminum-panel and framed-knee-wall variants now reveal different schema-backed controls instead of sharing one generic field set
    - reworked enclosure door options into conditional native pickers so hinged-screen and `PGT Cabana Door` variants reveal their own side/style/dimension fields
  - Scope folder project-type grouping pass:
    - grouped scopes inside the sidebar `Scopes` folder and the compact scopes list by the selected `Project Type`
    - reused schema-backed `ProjectType` labels so grouping stays aligned with the Project Information picker
    - kept the grouping treatment intentionally soft with lightweight headers instead of nested cards or extra glass chrome
  - Project type default/state refinement:
    - added a schema-backed `Not Set` option to the Project Information `Project Type` picker
    - made `Not Set` the default project type for newly created scopes so fresh jobs do not imply a category before selection
- Production notes are stored in `customerApproval.optionsConfirmedText` (schema-consistent text field already available).
- `schema.json` was updated when dropdown options / notes fields changed.

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
- Full acceptance verification is still pending for:
  - Dynamic Type clipping across all section editors
  - Light/Dark mode visual review on device/simulator
  - VoiceOver behavior for the newly adjusted toolbar/sidebar controls
- Liquid-glass visual review is still pending for:
  - actual feel on iPad split view versus compact navigation
  - whether toolbar chrome reads as polished or too decorative in dense editing contexts
  - whether preview/photo shell treatments feel cohesive with the rest of the app
- Maximalist-pass review is still pending for:
  - whether the glass treatment now overwhelms dense form-editing contexts
  - whether the background luminosity is still comfortable in Light/Dark mode for extended use
  - which parts of the extreme treatment should be kept, reduced, or removed entirely
- Unsandboxed `xcodebuild` validation succeeded on March 10, 2026 using:
  - `xcodebuild -project ConstructionScopeApp.xcodeproj -scheme ConstructionScopeApp -destination 'generic/platform=iOS' -derivedDataPath /tmp/ConstructionScopeAppDerived CODE_SIGNING_ALLOWED=NO build`
- Unsandboxed `xcodebuild` validation succeeded again on March 11, 2026 after Milestone 7.2 acceptance fixes using:
  - `xcodebuild -project ConstructionScopeApp.xcodeproj -scheme ConstructionScopeApp -destination 'generic/platform=iOS' -derivedDataPath /tmp/ConstructionScopeAppDerived CODE_SIGNING_ALLOWED=NO build`
- Unsandboxed `xcodebuild` validation succeeded again on March 11, 2026 after the Milestone 7.3 chrome pass using:
  - `xcodebuild -project ConstructionScopeApp.xcodeproj -scheme ConstructionScopeApp -destination 'generic/platform=iOS' -derivedDataPath /tmp/ConstructionScopeAppDerived CODE_SIGNING_ALLOWED=NO build`
- Unsandboxed `xcodebuild` validation succeeded again on March 11, 2026 after the Milestone 7.3 refinement pass using:
  - `xcodebuild -project ConstructionScopeApp.xcodeproj -scheme ConstructionScopeApp -destination 'generic/platform=iOS' -derivedDataPath /tmp/ConstructionScopeAppDerived CODE_SIGNING_ALLOWED=NO build`
- Unsandboxed `xcodebuild` validation succeeded again on March 11, 2026 after the Milestone 7.4 maximalist pass using:
  - `xcodebuild -project ConstructionScopeApp.xcodeproj -scheme ConstructionScopeApp -destination 'generic/platform=iOS' -derivedDataPath /tmp/ConstructionScopeAppDerived CODE_SIGNING_ALLOWED=NO build`
- Unsandboxed `xcodebuild` validation succeeded again on March 11, 2026 after the grouped-toolbar/input-consistency follow-up using:
  - `xcodebuild -project ConstructionScopeApp.xcodeproj -scheme ConstructionScopeApp -destination 'generic/platform=iOS' -derivedDataPath /tmp/ConstructionScopeAppDerived CODE_SIGNING_ALLOWED=NO build`
- Unsandboxed `xcodebuild` validation succeeded again on March 11, 2026 after the utility-surface consistency sweep using:
  - `xcodebuild -project ConstructionScopeApp.xcodeproj -scheme ConstructionScopeApp -destination 'generic/platform=iOS' -derivedDataPath /tmp/ConstructionScopeAppDerived CODE_SIGNING_ALLOWED=NO build`
- Unsandboxed `xcodebuild` validation succeeded again on March 11, 2026 after the full Liquid Glass compliance sweep using:
  - `xcodebuild -project ConstructionScopeApp.xcodeproj -scheme ConstructionScopeApp -destination 'generic/platform=iOS' -derivedDataPath /tmp/ConstructionScopeAppDerived CODE_SIGNING_ALLOWED=NO build`
- Unsandboxed `xcodebuild` validation succeeded again on March 11, 2026 after the Apple-correctness refinement pass using:
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
