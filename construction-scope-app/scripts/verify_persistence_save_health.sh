#!/usr/bin/env bash
set -euo pipefail
umask 077

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_TMP="$(mktemp -d /tmp/scope-persistence-save-health.XXXXXX)"

cleanup() {
  local status=$?
  if (( status == 0 )); then
    rm -rf -- "$TEST_TMP"
  else
    echo "Sanitized failure artifacts preserved at: $TEST_TMP" >&2
  fi
}
trap cleanup EXIT

fail() {
  echo "Persistence save health verification failed: $1" >&2
  exit 1
}

for required_tool in git grep sed xcrun; do
  command -v "$required_tool" >/dev/null 2>&1 || fail "required tool is unavailable: $required_tool"
done

HEALTH_SOURCE="$PROJECT_DIR/Persistence/PersistenceSaveHealth.swift"
HEALTH_TESTS="$PROJECT_DIR/PersistenceTests/PersistenceSaveHealthTests.swift"
PERSISTENCE_SOURCE="$PROJECT_DIR/Persistence/Persistence.swift"
ROOT_SOURCE="$PROJECT_DIR/Views/RootNavigationView.swift"
MODEL_SOURCE="$PROJECT_DIR/Models/SchemaModels.swift"
SCHEMA_SOURCE="$PROJECT_DIR/schema.json"

for required_file in \
  "$HEALTH_SOURCE" \
  "$HEALTH_TESTS" \
  "$PERSISTENCE_SOURCE" \
  "$ROOT_SOURCE" \
  "$MODEL_SOURCE" \
  "$SCHEMA_SOURCE"; do
  [[ -f "$required_file" ]] || fail "required source file is unavailable"
done

if grep -q 'localizedDescription' "$HEALTH_SOURCE" || \
   grep -Fq '\(error' "$HEALTH_SOURCE"; then
  fail "persistence health source exposes underlying save-error details"
fi

if ! git -C "$PROJECT_DIR" diff --quiet -- Models/SchemaModels.swift schema.json || \
   ! git -C "$PROJECT_DIR" diff --cached --quiet -- Models/SchemaModels.swift schema.json; then
  fail "the save-health slice changes the frozen persistence model or schema"
fi

if grep -Eq 'modelContext[[:space:]]*\.[[:space:]]*save[[:space:]]*\(' "$ROOT_SOURCE"; then
  fail "RootNavigationView contains a direct ModelContext save outside the shared health boundary"
fi

AUTOSAVE_SOURCE="$(sed -n '/final class DebouncedAutosave/,/final class SectionReviewStore/p' "$PERSISTENCE_SOURCE")"
if grep -q 'assertionFailure' <<<"$AUTOSAVE_SOURCE"; then
  fail "DebouncedAutosave contains assertion-only save failure handling"
fi

require_route() {
  local source="$1"
  local route="$2"
  grep -Fq "$route" "$source" || fail "required save-health route is missing: $route"
}

require_route "$PERSISTENCE_SOURCE" 'saveNow(.autosave)'
require_route "$PERSISTENCE_SOURCE" 'saveNow(.manualFlush)'
for operation in \
  createScope \
  renameScope \
  deleteScope \
  recordScopeAccess \
  hydrateLinkedCustomer \
  refreshLinkedCustomer; do
  require_route "$ROOT_SOURCE" "saveNow(.$operation)"
done

require_route "$ROOT_SOURCE" 'Text(issue.title)'
require_route "$ROOT_SOURCE" 'Text(issue.message)'
require_route "$ROOT_SOURCE" 'persistenceHealth.retry()'
require_route "$ROOT_SOURCE" '.accessibilityFocused('

WARNING_LAYER_COUNT="$(grep -Fc 'PersistenceSaveWarningLayer(persistenceHealth: autosave.persistenceHealth)' "$ROOT_SOURCE")"
if (( WARNING_LAYER_COUNT < 6 )); then
  fail "save-capable modal warning coverage is incomplete"
fi

xcrun swiftc \
  -parse-as-library \
  -strict-concurrency=complete \
  -warnings-as-errors \
  -module-cache-path "$TEST_TMP/ModuleCache" \
  "$HEALTH_SOURCE" \
  "$HEALTH_TESTS" \
  -o "$TEST_TMP/persistence-save-health-tests"

"$TEST_TMP/persistence-save-health-tests"
