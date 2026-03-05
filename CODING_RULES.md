# CODING_RULES.md

## Prime Directive
- Do not break working features.
- Do not refactor unrelated code.
- Prefer small, reversible changes.

## Git discipline
- Work in a branch for any task.
- Make small commits per logical change.
- Never commit build artifacts or user-specific files.

## SwiftUI discipline
- Keep UI native-first: Toggle/Picker/Segmented/TextEditor.
- Follow UI_SYSTEM.md (cards, grouped background, semantic typography, progressive disclosure).
- Avoid global refactors; change only what is necessary for the requested behavior.

## Data discipline
- schema.json is the source of truth for fields/enums.
- Optional fields must be resettable to nil ("Not Set") unless explicitly required.
- Do not auto-create optional nested objects unless the user enables that feature.

## Completion
- Update DOCUMENTATION.md with what changed + how to test.
- Stop after acceptance tests pass; do not continue into future milestones.
