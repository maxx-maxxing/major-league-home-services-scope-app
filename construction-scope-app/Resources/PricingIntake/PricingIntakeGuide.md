# Pricing Intake Deliverable

This folder is the first business-owned pricing intake handoff for the current pricing system.

Use these files:

- `PricingIntake_FillSheet.csv`: the sheet your brother should fill out.
- `PricingIntake_RuleReference.csv`: plain-language reference for what each pricing bucket controls.
- `PricingIntakeNormalization.md`: exact mapping from the completed sheet into the app's current JSON import boundary.

## Recommended format

The safest deliverable for this phase is spreadsheet-first, but not spreadsheet-dependent.

- Open `PricingIntake_FillSheet.csv` in Numbers, Excel, or Google Sheets.
- Open `PricingIntake_RuleReference.csv` as a second tab/reference sheet.
- If preferred, save them together as one workbook before sending it to your brother.

This keeps the business-facing process simple while preserving the current machine import contract.

## What your brother should edit

Only these columns need business input:

- `fillStatus`
- `businessNumericValue`
- `businessTextValue`
- `businessNotes`

All other columns are reference/mapping columns and should stay unchanged.

## How to fill it out

For each row:

1. Leave `ruleID`, `groupID`, `valueKind`, and `scheduleInputKey` exactly as-is.
2. Use `businessNumericValue` for money, percentages, hours, weeks, counts, and multipliers.
3. Use `businessTextValue` only for lookup names, tier keys, package keys, or other text schedule values.
4. If a row is not ready yet, leave the business value blank and keep `fillStatus` as `TODO`.
5. If a row is intentionally not used, mark `fillStatus` as `SKIP`.
6. Add context in `businessNotes` when the value depends on vendor, jurisdiction, product line, or assumption.

## Suggested `fillStatus` values

- `TODO`: still needs a real business value
- `READY`: reviewed and ready to import
- `SKIP`: intentionally leave the embedded baseline in place for now
- `HOLD`: needs follow-up before import

## Important behaviors

- Blank rows are safe. The current pricing system already falls back to the embedded draft baseline.
- Partial completion is safe. Only completed rows need to be normalized into import JSON.
- Text schedule rows are allowed. They map to `scheduleInput` rows with `stringValue`.
- Numeric schedule rows are allowed. They map to `scheduleInput` rows with `numericValue`.

## Handoff instruction for your brother

Tell him:

"Fill in the `businessNumericValue` or `businessTextValue` columns only. Leave the ID and mapping columns alone. If you are unsure about a row, leave it blank and add a note."

## What happens later

Once the sheet comes back:

- completed rows will be normalized into the existing `ImportedPricingRow` JSON shape
- the app will merge those rows onto the current embedded draft baseline by stable `ruleID`
- any missing values will continue using the embedded baseline until replaced
