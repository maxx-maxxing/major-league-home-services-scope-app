# ACCEPTANCE.md

The app is acceptable when:

## Core
- A complete scope can be entered in ~5 minutes using mostly pickers/toggles.
- Works offline; data persists after force close.
- Template cannot be edited; new jobs are created as copies.

## Apple Pencil
- Scribble works in long note fields (TextEditor).
- Signature capture works (PencilKit).
- Optional site diagram sketch works (PencilKit).

## UI Quality
- Looks excellent in Light and Dark mode.
- Supports Dynamic Type without clipping or broken layouts.
- Tap targets are ≥44x44 points.
- NavigationSplitView sidebar + detail behaves like native iPad apps.

## PDF
- Export creates a professional PDF production order.
- Exported PDF is flattened by default (not editable).
- PDF contains customer signature + signed date.
- Filename follows the configured convention.
