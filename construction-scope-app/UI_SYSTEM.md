# UI_SYSTEM.md

## Design Goal
The UI must feel like a **first‑party Apple app** (Files / Notes / Reminders). This is achieved through restraint:
system typography, correct spacing, system materials, and native iPad navigation patterns.

## Navigation
- iPad uses **NavigationSplitView**
  - Sidebar: sections list + job header (name + status)
  - Detail: section editor
  - Optional third column: PDF preview (nice-to-have)

## Layout Rules
- Use card groups with generous padding.
- Prefer grouped backgrounds and `.regularMaterial` for cards.
- Minimum tap target: **44x44**.
- Progressive disclosure: show dependent inputs only after enabling toggles/pickers.

## Typography (Semantic Only)
- App header / top titles: `.title2` / `.title3`
- Section headers: `.headline`
- Field labels: `.body`
- Helper text / metadata: `.footnote` / `.subheadline` (secondary)

Do not use custom fonts or fixed sizes.

## Color + Materials
- Use semantic colors: `.primary`, `.secondary`, `.tertiary`
- Background: system grouped background
- Cards: `.regularMaterial` (or grouped background insets)
- Accent color only for primary actions

## Controls
Prefer:
- Toggle (Yes/No)
- SegmentedControl (<=4 options)
- Picker (sheet / navigationLink style)
- TextEditor (notes; Scribble-friendly)

Avoid:
- fake checkboxes
- dense “wall of fields” forms
- heavy custom themes

## Apple Pencil
- Note fields: **TextEditor** (Scribble-to-text works automatically)
- Signature + diagram: PencilKit canvas with minimal tools (pen, marker, eraser; Clear/Done)

## Toolbar Pattern
- Leading: job name (editable) + subtle status pill
- Trailing: Preview, Export/Share, Photos, Sketch
- Use SF Symbols only (e.g., `doc.text.magnifyingglass`, `square.and.arrow.up`)
