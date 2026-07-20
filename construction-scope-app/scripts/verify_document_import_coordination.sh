#!/usr/bin/env bash
set -euo pipefail
umask 077

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_TMP="$(mktemp -d /tmp/scope-document-import-coordination.XXXXXX)"

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
  echo "Document import coordination verification failed: $1" >&2
  exit 1
}

require_text() {
  local file="$1"
  local text="$2"
  local message="$3"
  grep -Fq "$text" "$file" || fail "$message"
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

for required_tool in git grep plutil rg sed shasum xcrun; do
  command -v "$required_tool" >/dev/null 2>&1 || fail "required tool is unavailable: $required_tool"
done

COORDINATION_SOURCE="$PROJECT_DIR/Views/DocumentImportCoordination.swift"
COORDINATION_TESTS="$PROJECT_DIR/PersistenceTests/DocumentImportCoordinationTests.swift"
EDITOR_SOURCE="$PROJECT_DIR/Views/SectionEditors.swift"
RETIREMENT_SOURCE="$PROJECT_DIR/Persistence/DocumentAssetRetirement.swift"
STORE_SOURCE="$PROJECT_DIR/Views/PhotoAttachmentSupport.swift"
MODEL_SOURCE="$PROJECT_DIR/Models/SchemaModels.swift"
SCHEMA_SOURCE="$PROJECT_DIR/schema.json"
PROJECT_FILE="$PROJECT_DIR/ConstructionScopeApp.xcodeproj/project.pbxproj"

for required_file in \
  "$COORDINATION_SOURCE" \
  "$COORDINATION_TESTS" \
  "$EDITOR_SOURCE" \
  "$RETIREMENT_SOURCE" \
  "$STORE_SOURCE" \
  "$MODEL_SOURCE" \
  "$SCHEMA_SOURCE" \
  "$PROJECT_FILE"; do
  [[ -f "$required_file" ]] || fail "required source file is unavailable"
done

if ! git -C "$PROJECT_DIR" diff --quiet -- Models/SchemaModels.swift schema.json || \
   ! git -C "$PROJECT_DIR" diff --cached --quiet -- Models/SchemaModels.swift schema.json; then
  fail "the import-coordination slice changes the frozen persistence model or schema"
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
  'DocumentImportCoordination.swift in Sources' \
  "the coordination helper is missing from the app target"
require_text "$COORDINATION_SOURCE" \
  'let request = DocumentImportRequest(' \
  "request identity is not immutable"
require_text "$COORDINATION_SOURCE" \
  'guard isCurrent(request)' \
  "completion does not require exact current-request identity"
require_text "$COORDINATION_SOURCE" \
  'guard request.scopeID == currentScopeID' \
  "completion does not bind adoption to the captured scope"
require_text "$COORDINATION_SOURCE" \
  'guard targetExists(request.target)' \
  "completion does not reject a vanished target"

reject_rg_match \
  "coordination helper contains a diagnostic sink or raw error rendering" \
  -n '\b(Logger|print|debugPrint|dump|NSLog)\b|localizedDescription|String\(describing:[[:space:]]*error\)' \
  "$COORDINATION_SOURCE"
reject_rg_match \
  "the mutable active-slot completion route remains" \
  -n '\bactiveSlot\b|for target: DocumentSlotTarget\?' \
  "$EDITOR_SOURCE"
reject_rg_match \
  "DocumentSlotTarget remains duplicated in the editor" \
  -n 'private enum DocumentSlotTarget' \
  "$EDITOR_SOURCE"

require_text "$EDITOR_SOURCE" \
  'importCoordination.beginRequest(scopeID: scope.id, target: target)' \
  "presenter start does not create immutable request identity"
require_text "$EDITOR_SOURCE" \
  '.id(request?.id)' \
  "presenter callbacks are not rebound to request identity"
require_text "$EDITOR_SOURCE" \
  'handleFileImportResult(result, for: request)' \
  "file callback is not bound to its request"
require_text "$EDITOR_SOURCE" \
  'importSelectedPhotoItem(item, for: request)' \
  "photo callback is not bound before transferable loading"
require_text "$EDITOR_SOURCE" \
  'importCameraImage(image, for: request)' \
  "camera callback is not bound to its request"
require_text "$EDITOR_SOURCE" \
  'guard case .adopt = importCoordination.completionDecision(' \
  "camera file creation is not gated by current request identity"
require_text "$EDITOR_SOURCE" \
  'invalidateImportRequest(for: .additional(rowID))' \
  "row removal does not invalidate a matching request"
require_text "$EDITOR_SOURCE" \
  'invalidateImportRequest(for: target)' \
  "attachment clear does not invalidate a matching request"
require_text "$EDITOR_SOURCE" \
  'request.target == target' \
  "clearing an unrelated slot can invalidate the active request"
require_text "$EDITOR_SOURCE" \
  '.onDisappear {' \
  "editor disappearance does not invalidate active import state"
require_text "$EDITOR_SOURCE" \
  'let decision = importCoordination.resolveCompletion(' \
  "completion does not resolve through the coordination contract"
require_text "$EDITOR_SOURCE" \
  'case .discard(.staleRequest):' \
  "stale completion is not distinguished from a current terminal discard"
require_text "$EDITOR_SOURCE" \
  'retireNeverAdoptedAttachment(attachment, for: request)' \
  "discarded success does not reach never-adopted cleanup"

STALE_COMPLETION_SOURCE="$(
  sed -n '/case \.discard(\.staleRequest):/,/case \.discard:/p' "$EDITOR_SOURCE"
)"
if grep -Fq 'resetImportPresentation' <<<"$STALE_COMPLETION_SOURCE"; then
  fail "stale completion can reset a newer request's presentation"
fi

CAMERA_PICKER_SOURCE="$(
  sed -n '/onImagePicked: { image in/,/onCancel:/p' "$EDITOR_SOURCE"
)"
grep -Fq 'guard importCameraImage(image) else { return }' <<<"$CAMERA_PICKER_SOURCE" || \
  fail "camera sheet dismissal is not gated by request validation"

NEVER_ADOPTED_SOURCE="$(
  sed -n '/private func retireNeverAdoptedAttachment(/,/private func existingAttachment/p' "$EDITOR_SOURCE"
)"
grep -Fq 'request.scopeID == scope.id' <<<"$NEVER_ADOPTED_SOURCE" || \
  fail "never-adopted cleanup does not fail safe on scope identity"
grep -Fq '!Self.isAttachment(' <<<"$NEVER_ADOPTED_SOURCE" || \
  fail "never-adopted cleanup does not retain a referenced file"
grep -Fq 'DocumentAssetStore.retireAttachment(attachment, scopeID: request.scopeID)' \
  <<<"$NEVER_ADOPTED_SOURCE" || \
  fail "never-adopted cleanup does not use the captured scoped retirement API"

plutil -lint "$PROJECT_FILE" >/dev/null

xcrun swiftc \
  -swift-version 6 \
  -parse-as-library \
  -strict-concurrency=complete \
  -warnings-as-errors \
  -module-cache-path "$TEST_TMP/ModuleCache" \
  "$COORDINATION_SOURCE" \
  "$COORDINATION_TESTS" \
  -o "$TEST_TMP/document-import-coordination-tests"

"$TEST_TMP/document-import-coordination-tests"
"$PROJECT_DIR/scripts/verify_document_asset_retirement.sh"

echo "Document import coordination verification passed"
