#!/usr/bin/env bash
set -euo pipefail
umask 077

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PDF_DIR="$PROJECT_DIR/PDFEngine"
PDF_SOURCE="$PDF_DIR/PDFPreviewStubView.swift"

fail() {
  echo "PDF export diagnostic privacy verification failed: $1" >&2
  exit 1
}

reject_rg_match() {
  local message="$1"
  shift
  local status
  if rg "$@" >/dev/null; then
    fail "$message"
  else
    status=$?
    [[ "$status" -eq 1 ]] || fail "source scan could not complete: $message"
  fi
}

require_rg_match() {
  local message="$1"
  shift
  local status
  if rg "$@" >/dev/null; then
    return
  else
    status=$?
    [[ "$status" -eq 1 ]] || fail "source scan could not complete: $message"
    fail "$message"
  fi
}

for required_tool in awk git rg sed shasum wc tr; do
  command -v "$required_tool" >/dev/null 2>&1 || fail "required tool is unavailable: $required_tool"
done

[[ -f "$PDF_SOURCE" ]] || fail "PDF export source is unavailable"

if ! git -C "$PROJECT_DIR" diff --quiet -- Models/SchemaModels.swift schema.json || \
   ! git -C "$PROJECT_DIR" diff --cached --quiet -- Models/SchemaModels.swift schema.json; then
  fail "the PDF privacy slice changes the frozen persistence model or schema"
fi

EXPECTED_MODEL_HASH="f848b2307fa94c64e8efe8c31a0201950d2036f596a54dabfbf75aee8ddbaee8"
EXPECTED_SCHEMA_HASH="819b1b81ea23d3600ae83c05e073843f5036811c524b73bc743235be88a447f4"
read -r actual_model_hash _ < <(shasum -a 256 "$PROJECT_DIR/Models/SchemaModels.swift")
read -r actual_schema_hash _ < <(shasum -a 256 "$PROJECT_DIR/schema.json")
[[ "$actual_model_hash" == "$EXPECTED_MODEL_HASH" ]] || fail "the frozen Swift model hash changed"
[[ "$actual_schema_hash" == "$EXPECTED_SCHEMA_HASH" ]] || fail "the frozen schema hash changed"

LOGGER_DECLARATION_COUNT="$( (rg -n '\bLogger\s*\(' "$PDF_DIR" || true) | wc -l | tr -d '[:space:]')"
[[ "$LOGGER_DECLARATION_COUNT" == "1" ]] || fail "PDFEngine must contain exactly one canonical Logger declaration"
require_rg_match \
  "the canonical PDF Logger declaration is missing" \
  -n 'private static let logger = Logger\(subsystem: "ConstructionScopeApp", category: "PDFExport"\)' \
  "$PDF_SOURCE"

ALL_DIAGNOSTIC_CALL_COUNT="$(
  (rg -U --pcre2 --count-matches --no-filename \
    '(?s)(?<![A-Za-z0-9_])(?:[A-Za-z_][A-Za-z0-9_.]*)\.(?:trace|debug|info|notice|warning|error|critical|log)\s*\(' \
    "$PDF_DIR" || true) | awk '{ total += $1 } END { print total + 0 }'
)"
CANONICAL_DIAGNOSTIC_CALL_COUNT="$(
  (rg -U --pcre2 --count-matches --no-filename \
    '(?s)(?<![A-Za-z0-9_.])logger\.(?:trace|debug|info|notice|warning|error|critical)\(\s*"(?:\\.|[^"\\])*"\s*\)' \
    "$PDF_DIR" || true) | awk '{ total += $1 } END { print total + 0 }'
)"
[[ "$ALL_DIAGNOSTIC_CALL_COUNT" == "$CANONICAL_DIAGNOSTIC_CALL_COUNT" ]] || \
  fail "every PDF diagnostic must use the canonical logger with one literal message argument"

reject_rg_match \
  "a PDF diagnostic interpolates customer-, scope-, filename-, path-, title-, label-, text-, or context-derived data" \
  -U -n --pcre2 '(?s)\blogger\.(?:trace|debug|info|notice|warning|error|critical)\(\s*"(?:\\.|[^"\\]){0,1200}?\\\([^)]*(?:scope|customer|filename|outputURL|path|page\.title|section\.title|row\.label|logContext|reasonContext|summary|plannedTitles|renderedTitles)' \
  "$PDF_DIR"

reject_rg_match \
  "a PDF diagnostic interpolates a value outside the reviewed numeric/boolean allowlist" \
  -U -n --pcre2 '(?s)\blogger\.(?:trace|debug|info|notice|warning|error|critical)\(\s*"(?:\\.|[^"\\])*?\\\((?!(?:render\.data\.count|render\.missingFields\.count|diagnostics\.missingFieldCount|diagnostics\.plannedPageCount|diagnostics\.renderedPageCount|diagnostics\.renderedSectionCount|diagnostics\.appendixPageCount|actualPageCount|renderedPages\.count|data\.count|currentPage\.sections\.count(?:\s*\+\s*1)?|output\.count\s*\+\s*1|remainingHeight|fitted\.scaled|fitted\.truncated)\s*,\s*privacy:\s*\.public\))' \
  "$PDF_DIR"

reject_rg_match \
  "a PDF diagnostic still marks string/path content private instead of omitting it" \
  -U -n --pcre2 '(?s)\blogger\.(?:trace|debug|info|notice|warning|error|critical)\(\s*"(?:\\.|[^"\\]){0,1200}?privacy:\s*\.private' \
  "$PDF_DIR"

reject_rg_match \
  "an alternate console or OS diagnostic sink remains in the PDF export path" \
  -n --pcre2 '\b(?:print|debugPrint|dump|NSLog|os_log|os_signpost|OSSignposter)\s*\(|\.(?:beginInterval|emitEvent|endInterval|withIntervalSignpost)\s*\(' \
  "$PDF_DIR"

DIAGNOSTIC_MODEL="$(sed -n '/private struct PDFRenderDiagnostics/,/^}/p' "$PDF_SOURCE")"
if rg -n '\b(scopeID|filename|missingFields|plannedTitles|renderedTitles|summary)\b' <<<"$DIAGNOSTIC_MODEL" >/dev/null; then
  fail "PDFRenderDiagnostics retains render-derived string data"
fi

require_rg_match \
  "PDF diagnostics no longer retain numeric render counts" \
  -U -n 'private struct PDFRenderDiagnostics(?s:.*?)let missingFieldCount: Int(?s:.*?)let plannedPageCount: Int(?s:.*?)let renderedPageCount: Int(?s:.*?)let renderedSectionCount: Int(?s:.*?)let appendixPageCount: Int' \
  "$PDF_SOURCE"

require_rg_match \
  "the customer-facing PDF filename path changed unexpectedly" \
  -n 'let filename = makeFilename\(for: scope\)' \
  "$PDF_SOURCE"
require_rg_match \
  "the customer-facing PDF file extension path changed unexpectedly" \
  -n '\.appendingPathComponent\(render\.filename\)' \
  "$PDF_SOURCE"
require_rg_match \
  "the PDF render result no longer returns its existing filename" \
  -n 'return \(data: data, missingFields: missing, filename: filename\)' \
  "$PDF_SOURCE"

require_rg_match \
  "the fixed share-ready diagnostic is missing" \
  -n 'share-ready PDF written bytes=' \
  "$PDF_SOURCE"
require_rg_match \
  "the fixed render-start diagnostic is missing" \
  -n 'starting PDF render plannedPages=' \
  "$PDF_SOURCE"
require_rg_match \
  "the fixed render-complete diagnostic is missing" \
  -n 'completed PDF render actualPages=' \
  "$PDF_SOURCE"

echo "PDF export diagnostic privacy verification passed"
