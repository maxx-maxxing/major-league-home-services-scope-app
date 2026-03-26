# Pricing Intake Normalization Contract

This document defines how the completed pricing intake sheet maps back into the app's current machine-readable pricing import boundary.

The current import boundary is already implemented in:

- [PricingProposalFoundation.swift](/Users/maxx/Documents/major-league-home-services-scope-app/construction-scope-app/Models/PricingProposalFoundation.swift)
- [BusinessOwnedPricingRows.json](/Users/maxx/Documents/major-league-home-services-scope-app/construction-scope-app/Resources/BusinessOwnedPricingRows.json)

## Current import row shape

The app currently imports rows shaped like this:

```json
{
  "ruleID": "structure.base_package",
  "groupID": "base-structure",
  "valueKind": "draftUnitPrice",
  "numericValue": 36,
  "notes": "Business-owned unit sell price."
}
```

Schedule-input rows use the same shape plus `scheduleInputKey`, and may use either `numericValue` or `stringValue`:

```json
{
  "ruleID": "windows.system_selection",
  "groupID": "enclosure-options",
  "valueKind": "scheduleInput",
  "scheduleInputKey": "glass_modifier_table",
  "title": "Glass modifier table key",
  "stringValue": "glass_default",
  "notes": "Lookup key from completed pricing intake sheet."
}
```

## Spreadsheet-to-JSON mapping

For each row in `PricingIntake_FillSheet.csv`:

- Keep `ruleID` as `ruleID`
- Keep `groupID` as `groupID`
- Keep `valueKind` as `valueKind`
- Keep `scheduleInputKey` as `scheduleInputKey` when present
- Map `businessNumericValue` to `numericValue` when populated
- Map `businessTextValue` to `stringValue` when populated
- Map `businessLabel` to `title` for `scheduleInput` rows
- Map `businessNotes` to `notes` when populated

## Row inclusion rules

Emit a JSON row only when one of these is true:

- `businessNumericValue` is populated
- `businessTextValue` is populated

Do not emit a JSON row when:

- both business value columns are blank
- `fillStatus` is `SKIP`

If `fillStatus` is `TODO` or `HOLD` and a business value is still blank, omit the row.

## Validation expectations

The current importer already enforces these rules:

- unknown `ruleID` rows are ignored
- mismatched `groupID` rows are ignored
- `draftUnitCost`, `draftUnitPrice`, `allowanceAmount`, `feeAmount`, and `markupPercent` require `numericValue`
- `scheduleInput` rows require `scheduleInputKey`
- `scheduleInput` rows must provide either `numericValue` or `stringValue`

## Practical normalization rules

Use these normalization rules when converting the completed sheet:

1. Trim whitespace from all business-entered cells.
2. Keep IDs and enum values exact. Do not rename `ruleID`, `groupID`, `valueKind`, or `scheduleInputKey`.
3. Convert currency, percent, hours, weeks, counts, and multipliers to numbers in `numericValue`.
4. Keep lookup names, tier names, and package keys as `stringValue`.
5. Preserve `businessNotes` in `notes` for traceability.
6. Ignore the `currentDraftBaseline` column during normalization. It is reference-only.

## Recommended conversion workflow

When the completed sheet comes back:

1. Filter rows to `READY` plus any other rows that have a real business value.
2. Normalize those rows into an array of `ImportedPricingRow` objects.
3. Save the normalized file as JSON.
4. Replace or supplement the sample content in [BusinessOwnedPricingRows.json](/Users/maxx/Documents/major-league-home-services-scope-app/construction-scope-app/Resources/BusinessOwnedPricingRows.json).
5. Rebuild the app and inspect the active scope in the debug pricing inspector.

## Example normalization result

```json
[
  {
    "ruleID": "structure.base_package",
    "groupID": "base-structure",
    "valueKind": "draftUnitCost",
    "numericValue": 31.5,
    "notes": "Brother confirmed updated material/labor baseline."
  },
  {
    "ruleID": "structure.base_package",
    "groupID": "base-structure",
    "valueKind": "draftUnitPrice",
    "numericValue": 47,
    "notes": "Brother confirmed updated sell rate."
  },
  {
    "ruleID": "windows.system_selection",
    "groupID": "enclosure-options",
    "valueKind": "scheduleInput",
    "scheduleInputKey": "glass_modifier_table",
    "title": "Glass modifier table key",
    "stringValue": "premium_low_e_table",
    "notes": "Use for the current premium glass family."
  }
]
```

## Explicit deferrals

This pass does not add:

- CSV parsing code
- spreadsheet import UI
- a workbook generator
- final totals logic
- final PDF pricing output
- final JobTread sync submission

The goal here is to make the completed sheet easy to normalize into the current import seam without changing the seam itself.
