# PDF_EXPORT.md

## Goal
Produce a **professional production-order PDF** that crews can build from.
The exported PDF must be **flattened** by default (no editable form fields).

## Layout Outline
- Page 1: Job header + Project Info
- Page 2: Existing Conditions + Attachment Conditions
- Page 3: Structural + Roof System + Screen Enclosure summary
- Page 4: Sunroom + Knee Wall + Electrical + Drainage
- Page 5: Permits/HOA + Production Notes + Customer Signature

Measurements are section-owned. Enabled Measurements rows render under their owning section:
- Structural System
- Screen Enclosure
- Sunroom
- Electrical
- Drainage
- Attachment Conditions
- Finishes

Disabled/hidden Measurements blocks must not render in PDF output.

Optional appendices:
- Photos
- Site diagram / sketch

## Header/Footer
Header should include:
- Client name
- Job address
- Project type
- Job number (optional)
Footer should include:
- Generated date/time
- Page X of Y

## Rendering Rules
- Consistent section titles
- Selected options rendered clearly (checkmarks or filled chips)
- Notes wrap and preserve whitespace reasonably
- Signature image embedded with signed date

## Export Flow
1. Preview PDF (and show missing required fields)
2. Export/Share flattened PDF via share sheet
3. Save to Files / send to customer / attach in Job management system
