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

## Milestone 3 – Pencil Support
- Ensure TextEditor note fields support Scribble
- PencilKit signature capture page
- Optional: PencilKit site diagram page with minimal tools

## Milestone 4 – PDF Preview + Export
- Build PDF engine that renders a flattened PDF (PDFKit/CoreGraphics)
- Implement Preview screen
- Implement Export/Share flow (ShareLink/Files)
- Follow PDF_EXPORT.md layout outline

## Milestone 5 – Photos Appendix (Optional)
- Photo capture per checklist
- Store locally, add appendix pages in PDF export

## Milestone 6 – Acceptance + Polish
- Run through ACCEPTANCE.md checklist
- Dark mode verification
- Dynamic Type verification
- Tap target verification
- Light performance polish and accessibility labels
