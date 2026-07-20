#!/usr/bin/env bash
set -euo pipefail
umask 077

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_TMP="$(mktemp -d /tmp/scope-document-asset-retirement.XXXXXX)"

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
  echo "Document asset retirement verification failed: $1" >&2
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

require_text() {
  local file="$1"
  local text="$2"
  local message="$3"
  grep -Fq "$text" "$file" || fail "$message"
}

for required_tool in git grep plutil rg sed shasum xcrun; do
  command -v "$required_tool" >/dev/null 2>&1 || fail "required tool is unavailable: $required_tool"
done

RETIREMENT_SOURCE="$PROJECT_DIR/Persistence/DocumentAssetRetirement.swift"
RETIREMENT_TESTS="$PROJECT_DIR/PersistenceTests/DocumentAssetRetirementTests.swift"
HEALTH_SOURCE="$PROJECT_DIR/Persistence/PersistenceSaveHealth.swift"
PERSISTENCE_SOURCE="$PROJECT_DIR/Persistence/Persistence.swift"
STORE_SOURCE="$PROJECT_DIR/Views/PhotoAttachmentSupport.swift"
EDITOR_SOURCE="$PROJECT_DIR/Views/SectionEditors.swift"
MODEL_SOURCE="$PROJECT_DIR/Models/SchemaModels.swift"
SCHEMA_SOURCE="$PROJECT_DIR/schema.json"
PROJECT_FILE="$PROJECT_DIR/ConstructionScopeApp.xcodeproj/project.pbxproj"

for required_file in \
  "$RETIREMENT_SOURCE" \
  "$RETIREMENT_TESTS" \
  "$HEALTH_SOURCE" \
  "$PERSISTENCE_SOURCE" \
  "$STORE_SOURCE" \
  "$EDITOR_SOURCE" \
  "$MODEL_SOURCE" \
  "$SCHEMA_SOURCE" \
  "$PROJECT_FILE"; do
  [[ -f "$required_file" ]] || fail "required source file is unavailable"
done

if ! git -C "$PROJECT_DIR" diff --quiet -- Models/SchemaModels.swift schema.json || \
   ! git -C "$PROJECT_DIR" diff --cached --quiet -- Models/SchemaModels.swift schema.json; then
  fail "the retirement slice changes the frozen persistence model or schema"
fi

EXPECTED_MODEL_HASH="f848b2307fa94c64e8efe8c31a0201950d2036f596a54dabfbf75aee8ddbaee8"
EXPECTED_SCHEMA_HASH="819b1b81ea23d3600ae83c05e073843f5036811c524b73bc743235be88a447f4"
EXPECTED_PROJECT_HASH="1219995261ff7b4acb20c9ecbeaa782915d303132306b0fedee5807aee7ec569"
read -r actual_model_hash _ < <(shasum -a 256 "$MODEL_SOURCE")
read -r actual_schema_hash _ < <(shasum -a 256 "$SCHEMA_SOURCE")
read -r actual_project_hash _ < <(shasum -a 256 "$PROJECT_FILE")
[[ "$actual_model_hash" == "$EXPECTED_MODEL_HASH" ]] || fail "the frozen Swift model hash changed"
[[ "$actual_schema_hash" == "$EXPECTED_SCHEMA_HASH" ]] || fail "the frozen schema hash changed"
[[ "$actual_project_hash" == "$EXPECTED_PROJECT_HASH" ]] || fail "the reviewed Xcode source membership changed"

require_text "$PROJECT_FILE" \
  'DocumentAssetRetirement.swift in Sources' \
  "the retirement helper is missing from the app target"
require_text "$RETIREMENT_SOURCE" 'O_NOFOLLOW' "directory traversal is not symlink-safe"
require_text "$RETIREMENT_SOURCE" 'AT_SYMLINK_NOFOLLOW' "final target inspection follows symlinks"
require_text "$RETIREMENT_SOURCE" 'fstatat(' "final target type is not inspected through the anchored directory"
require_text "$RETIREMENT_SOURCE" 'unlinkat(' "retirement is not anchored to the managed directory"
require_text "$RETIREMENT_SOURCE" 'fileType == mode_t(S_IFREG)' "non-regular targets are not rejected"

reject_rg_match \
  "retirement helper contains a diagnostic sink or raw error rendering" \
  -n '\b(Logger|print|debugPrint|dump|NSLog)\b|localizedDescription|String\(describing:[[:space:]]*error\)' \
  "$RETIREMENT_SOURCE"

reject_rg_match \
  "the old raw-path Documents deletion API remains" \
  -n 'DocumentAssetStore\.removeAttachment|static func removeAttachment\(at path:' \
  "$STORE_SOURCE" "$EDITOR_SOURCE"

RETIREMENT_ROUTE_COUNT="$(grep -Fc 'updateDocuments(retiring:' "$EDITOR_SOURCE")"
[[ "$RETIREMENT_ROUTE_COUNT" == "3" ]] || fail "replace, clear, and row deletion do not share the retirement route"

EDITOR_RETIREMENT_SOURCE="$(
  sed -n '/private func updateDocuments(/,/private func documentAttachmentSymbol/p' "$EDITOR_SOURCE"
)"
grep -Fq 'autosave.flush(' <<<"$EDITOR_RETIREMENT_SOURCE" || fail "destructive metadata changes are not flushed immediately"
grep -Fq 'afterConfirmedSave:' <<<"$EDITOR_RETIREMENT_SOURCE" || fail "retirement is not gated by confirmed save success"
grep -Fq '!Self.isAttachment(' <<<"$EDITOR_RETIREMENT_SOURCE" || fail "still-referenced attachments are not retained"
grep -Fq 'DocumentAssetStore.retireAttachment(' <<<"$EDITOR_RETIREMENT_SOURCE" || fail "confirmed retirement does not reach the scoped store API"

require_text "$HEALTH_SOURCE" \
  'pendingConfirmedSaveActions.append(action)' \
  "confirmed actions are not retained before save attempts"
require_text "$HEALTH_SOURCE" \
  'pendingConfirmedSaveActions.removeAll()' \
  "confirmed actions are not drained exactly once"
require_text "$PERSISTENCE_SOURCE" \
  'saveNow(.manualFlush, afterConfirmedSave: action)' \
  "manual flush does not forward confirmed-save actions"

plutil -lint "$PROJECT_FILE" >/dev/null

xcrun swiftc \
  -parse-as-library \
  -strict-concurrency=complete \
  -warnings-as-errors \
  -module-cache-path "$TEST_TMP/ModuleCache" \
  "$RETIREMENT_SOURCE" \
  "$RETIREMENT_TESTS" \
  -o "$TEST_TMP/document-asset-retirement-tests"

"$TEST_TMP/document-asset-retirement-tests"
"$PROJECT_DIR/scripts/verify_persistence_save_health.sh"

echo "Document asset retirement verification passed"
