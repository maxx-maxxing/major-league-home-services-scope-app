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
