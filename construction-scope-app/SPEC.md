# SPEC.md

## Summary
Build an unlisted internal app for construction field scoping. Estimators fill a structured scope on iPad (tap-first + Apple Pencil).
The app exports a professional, flattened **PDF production order** suitable for crews and customers.

Primary project types:
- Patio covers
- Screen rooms
- Sunrooms
- Decks
- Pergolas
- Concrete patios
- Other

## Golden Path Workflow
1. Home → **New Scope** (creates a JobScope from a locked template)
2. Fill sections (sidebar navigation)
3. Preview PDF (shows missing required fields)
4. Capture customer signature
5. Export flattened PDF (Share → Save to Files / send / upload)

## Sections
1. Project Information
2. Existing Conditions
3. Dimensions
4. Structural System
5. Enclosure
6. Windows & Glass
7. Electrical
8. Drainage
9. Attachment Conditions
10. Finishes
11. Permits / HOA
12. Production Notes
13. Signature & Export

## Enclosure Requirements
### Screen Wall Types
- 18x14 Standard Fiberglass Screen
- 20x20 No‑See‑Um Screen
- 18x14 Tuff Screen
- 20x20 Tuff Screen

### Knee Wall Options
- None
- Aluminum Kickplate
- Framed Knee Wall
- Insulated Aluminum Panel Knee Wall

### Window Systems
- PGT Eze‑Breeze Vertical 4‑Track Vinyl Windows
- Double Pane Insulated Glass Windows

### Window Frame Systems
- Standard Patio Extrusion Framing
- Heavy Duty Patio Extrusion Framing
- Thermally Broken Insulated Framing

### Glass Types + Safety
Glass Type:
- Clear
- Low‑E
- Tinted

Safety Rating:
- Standard Annealed
- Tempered Safety Glass
- Tempered Required by Code

## Attachment Conditions Requirements
Capture what you are attaching to:
- Exterior house wall material (brick, stucco, siding, etc.)
- Posts / columns material and condition

Trim around posts:
- Present? Yes/No
- Trim material
- Trim thickness (enum + custom field)

## Apple Pencil Requirements
- Long text areas must support Scribble-to-text (TextEditor).
- Signature and diagram pages use PencilKit.

## PDF Requirements
- Flattened (non-editable) by default
- Clean professional layout
- Clear section headers and selected options
- Include customer signature + signed date
- Filename convention is configurable; default pattern:
  `{ClientLastName}-{StreetNumber}{StreetName}-{ProjectType}-Scope.pdf`
