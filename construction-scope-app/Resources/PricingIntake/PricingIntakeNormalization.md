# Pricing Intake Normalization Contract

This document defines how the completed pricing intake sheet maps back into the app's current machine-readable pricing import boundary.

The current import boundary is already implemented in:

- [PricingProposalFoundation.swift](/Users/maxx/Documents/major-league-home-services-scope-app/construction-scope-app/Models/PricingProposalFoundation.swift)
- [BusinessOwnedPricingRows.json](/Users/maxx/Documents/major-league-home-services-scope-app/construction-scope-app/Resources/BusinessOwnedPricingRows.json)

The first supported completed-sheet return format is now:

- [ReturnedPricingSheetRows.json](/Users/maxx/Documents/major-league-home-services-scope-app/construction-scope-app/Resources/ReturnedPricingSheetRows.json)

This file mirrors the business-facing fill-sheet columns directly so returned workbook rows can be normalized and validated before they are converted into `ImportedPricingRow`.

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

For the first supported return path, each completed worksheet row should first be represented as one `ReturnedPricingSheetRow` JSON object with the same columns as the fill sheet:

- `fillStatus`
- `pricingGroupTitle`
- `pricingItemTitle`
- `businessLabel`
- `whatToEnter`
- `ruleID`
- `groupID`
- `valueKind`
- `scheduleInputKey`
- `expectedValueType`
- `unitLabel`
- `currentDraftBaseline`
- `businessNumericValue`
- `businessTextValue`
- `businessNotes`

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

The completed-sheet normalizer/importer now enforces these rules:

- missing `ruleID` rows are ignored
- unknown `ruleID` rows are ignored
- mismatched `groupID` rows are ignored
- conflicting filled values (`businessNumericValue` plus `businessTextValue`) are ignored
- duplicate normalized rows are de-duplicated safely
- conflicting duplicate normalized rows are ignored
- `draftUnitCost`, `draftUnitPrice`, `allowanceAmount`, `feeAmount`, and `markupPercent` require `numericValue`
- `scheduleInput` rows require `scheduleInputKey`
- `scheduleInput` rows must provide either `numericValue` or `stringValue`
- `SKIP` rows are intentionally ignored
- blank `TODO` / `HOLD` rows are skipped without affecting the embedded baseline

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

1. Export or transcribe the completed workbook rows into [ReturnedPricingSheetRows.json](/Users/maxx/Documents/major-league-home-services-scope-app/construction-scope-app/Resources/ReturnedPricingSheetRows.json) using the same columns as the fill sheet.
2. Rebuild the app.
3. Let the app normalize those returned rows into `ImportedPricingRow` data internally.
4. Inspect the active scope in the debug pricing inspector for:
   - active pricing source
   - returned-sheet normalization counts
   - validation issues
   - applied imported rows
5. Use [BusinessOwnedPricingRows.json](/Users/maxx/Documents/major-league-home-services-scope-app/construction-scope-app/Resources/BusinessOwnedPricingRows.json) only for the older direct-import fallback path.

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
