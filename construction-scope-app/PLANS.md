# PLANS.md
# Milestone Plan – Construction Scope App

This is the milestone-by-milestone plan. Treat this file as the **source of truth** for implementation order.
Keep milestones small, testable, and reviewable.

## Milestone 0 – Repo + App Skeleton
- Create Xcode project (SwiftUI)
- Create folder structure:
  - App/
  - Models/
  - Persistence/
  - Views/
  - Components/
  - Features/ (optional)
  - PDFEngine/
  - Resources/
- Add basic navigation scaffold with NavigationSplitView (iPad) and NavigationStack (iPhone)

## Milestone 1 – Data Model + Persistence
- Implement Swift models that match `schema.json`
- Add local persistence using SwiftData (preferred) or CoreData
- Autosave behavior (debounced)
- Template immutability (read-only template defaults; New Scope instantiates copy)

## Milestone 2 – Section Editor UX (First-Party)
- Sidebar sections list
- Detail editors for:
  - Project Info
  - Enclosure
  - Windows & Glass
  - Attachments
  - Production Notes
- Apply UI_SYSTEM.md rules: cards, materials, semantic type, progressive disclosure

## Milestone 2.2 – Remaining Section Editors
- Implement the remaining schema-backed editors for:
  - Existing Conditions
  - Dimensions
  - Structural System
  - Electrical
  - Drainage
  - Finishes
  - Permits / HOA
- Replace placeholder section states in navigation/editor routing
- Keep controls native and Scribble-friendly where notes are required
- Validate autosave + relaunch behavior for each newly added section

## Milestone 3 – Pencil Support
- Ensure TextEditor note fields support Scribble
- PencilKit signature capture page
- Optional: PencilKit site diagram page with minimal tools
- Milestone 3.1 – PencilKit Foundation
  - Add a reusable PencilKit canvas bridge for SwiftUI
  - Support load/save of PKDrawing data + PNG previews
- Milestone 3.2 – Signature Capture UX
  - Replace Signature & Export placeholder with a signature editor
  - Capture customer signature + signed date into `customerApproval`
  - Capture salesperson signature as a saved sketch attachment
- Milestone 3.3 – Site Diagram UX
  - Add optional site diagram canvas with clear action
  - Persist diagram to `sketches` with autosave behavior
- Milestone 3.4 – Milestone Validation + Docs
  - Verify relaunch persistence for signature/diagram
  - Update `DOCUMENTATION.md` with milestone status and known follow-ups

## Milestone 4 – PDF Preview + Export
- Build PDF engine that renders a flattened PDF (PDFKit/CoreGraphics)
- Implement Preview screen
- Implement Export/Share flow (ShareLink/Files)
- Follow PDF_EXPORT.md layout outline
- Milestone 4.1 – PDF Data Mapping
  - Define printable summary rows for each schema section
  - Add missing-field checks used by preview warnings
- Milestone 4.2 – Flattened PDF Renderer
  - Implement CoreGraphics renderer with fixed page layout + wrapped notes
  - Add header/footer (project metadata + page X of Y + generated timestamp)
  - Embed customer signature image + signed date
- Milestone 4.3 – Preview Experience
  - Replace PDF stub with a PDFKit-backed preview view
  - Surface missing required fields before export
- Milestone 4.4 – Export/Share Flow
  - Generate PDF file to app temp directory using naming convention
  - Wire toolbar actions for Preview and Share/Export
- Milestone 4.5 – Validation + Docs
  - Validate generated PDF opens and contains expected sections
  - Update `DOCUMENTATION.md` with implementation notes and follow-ups
- Milestone 4.6 – Expanded PDF Coverage
  - Extend the five-page PDF mapping to reflect the newly implemented section editors
  - Add richer summaries for existing conditions, dimensions, structural, electrical, drainage, finishes, and permits/production notes
  - Preserve flattened rendering and current export flow
  - Validate that preview/export still builds and opens successfully

## Milestone 5 – JobTread Integration
- Milestone 5.1 – Integration Readiness Freeze
  - Confirm `schema.json` fields/enums used for integration are stable
  - Finalize canonical string/enum mapping table between app model and JobTread objects
  - Confirm required/optional field behavior and default values
- Milestone 5.2 – API Foundation
  - Add secure credential/config handling for JobTread API access
  - Add typed API client + request/response models
  - Add resilient networking (timeouts, retry/backoff, offline queue strategy)
- Milestone 5.3 – Initial Sync Flow (One-Way)
  - Implement manual `Send to JobTread` action per scope
  - Map core scope entities into JobTread entities (customer/location/job/etc.)
  - Upload supported artifacts (signature/diagram and other attachments as applicable)
- Milestone 5.4 – Sync UX + Operations
  - Add per-scope sync status (never sent / in progress / success / failed)
  - Add actionable error UI and retry controls
  - Add integration logs/diagnostics suitable for support troubleshooting
- Milestone 5.5 – Validation
  - Validate payload correctness against JobTread docs/sandbox
  - Verify idempotency to prevent duplicate records on retry
  - Document mapping assumptions and known gaps

## Milestone 6 – Photos Appendix (Optional)
- Photo capture per checklist
- Store locally, add appendix pages in PDF export
- Milestone 6.1 – Photo Attachment Flow
  - Add a native photo management sheet from the toolbar
  - Support selecting photos from the photo library
  - Persist photos locally under the scope asset directory with captions
- Milestone 6.2 – PDF Photo Appendix
  - Append stored scope photos to the exported PDF
  - Include captions/created timestamps with each photo page
- Milestone 6.3 – Validation + Docs
  - Verify added photos relaunch correctly
  - Verify the PDF includes photo appendix pages when photos exist
  - Update `DOCUMENTATION.md` with implementation details and follow-ups

## Milestone 7 – Acceptance + Polish
- Run through ACCEPTANCE.md checklist
- Dark mode verification
- Dynamic Type verification
- Tap target verification
- Light performance polish and accessibility labels

## Milestone 7.1 – Interaction Animation Polish
- Add motion to key UI state changes so content changes are visually legible
- Prioritize:
  - scope selection transitions
  - section switching in the detail pane
  - sidebar folder expansion/collapse
  - modal/sheet presentation polish where current changes feel abrupt
- Keep animations subtle, fast, and system-aligned rather than decorative
- Validate that animations do not interfere with autosave, selection state, or accessibility
