#!/usr/bin/env bash
set -euo pipefail
umask 077

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(git -C "$PROJECT_DIR" rev-parse --show-toplevel)"
BASELINE_REF="07b42f308cee328926046f3198bbaa5fe36fa43b"
TEST_TMP="$(mktemp -d /tmp/scope-persistence-compatibility.XXXXXX)"

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
  echo "Persistence compatibility verification failed: $1" >&2
  exit 1
}

for required_tool in git tar xcrun plutil ln unlink; do
  command -v "$required_tool" >/dev/null 2>&1 || fail "required tool is unavailable: $required_tool"
done

git -C "$REPO_ROOT" cat-file -e "${BASELINE_REF}^{commit}" 2>/dev/null || \
  fail "pinned repository baseline cannot be resolved"

mkdir -p "$TEST_TMP/baseline"
git -C "$REPO_ROOT" archive \
  --format=tar \
  --output="$TEST_TMP/baseline.tar" \
  "${BASELINE_REF}:construction-scope-app" \
  Models/SchemaModels.swift \
  schema.json || fail "baseline model contract could not be extracted"
tar -xf "$TEST_TMP/baseline.tar" -C "$TEST_TMP/baseline" || \
  fail "baseline model archive could not be unpacked"

BASELINE_MODEL="$TEST_TMP/baseline/Models/SchemaModels.swift"
BASELINE_SCHEMA="$TEST_TMP/baseline/schema.json"
CURRENT_MODEL="$PROJECT_DIR/Models/SchemaModels.swift"
CURRENT_SCHEMA="$PROJECT_DIR/schema.json"
SUPPORT_FILE="$PROJECT_DIR/PersistenceTests/JobTreadModelTestSupport.swift"
FIXTURE_VALUES_FILE="$PROJECT_DIR/PersistenceTests/PersistenceFixtureValues.swift"
PATH_GUARD_FILE="$PROJECT_DIR/PersistenceTests/PersistenceHarnessPathGuard.swift"
BASELINE_WRITER_SOURCE="$PROJECT_DIR/PersistenceTests/BaselineStoreWriter.swift"
CURRENT_VERIFIER_SOURCE="$PROJECT_DIR/PersistenceTests/CurrentStoreVerifier.swift"

for required_file in \
  "$BASELINE_MODEL" \
  "$BASELINE_SCHEMA" \
  "$CURRENT_MODEL" \
  "$CURRENT_SCHEMA" \
  "$SUPPORT_FILE" \
  "$FIXTURE_VALUES_FILE" \
  "$PATH_GUARD_FILE" \
  "$BASELINE_WRITER_SOURCE" \
  "$CURRENT_VERIFIER_SOURCE"; do
  [[ -f "$required_file" ]] || fail "required source file is unavailable"
done

bundled_secret_file=""
if ! bundled_secret_file="$(find "$TEST_TMP" -name 'JobTreadSecrets.xcconfig' -print -quit)"; then
  fail "temporary compatibility workspace could not be inspected"
fi
[[ -z "$bundled_secret_file" ]] || \
  fail "temporary compatibility workspace contains a local secret configuration file"

assert_schema_value() {
  local key_path="$1"
  local expected_value="$2"
  local actual_value
  if ! actual_value="$(plutil -extract "$key_path" raw -o - "$CURRENT_SCHEMA" 2>/dev/null)"; then
    fail "schema.json is missing candidate contract key: $key_path"
  fi
  [[ "$actual_value" == "$expected_value" ]] || \
    fail "schema.json candidate contract mismatch: $key_path"
}

if plutil -extract entities.JobScope.fields.voiceNotes json -o - "$BASELINE_SCHEMA" >/dev/null 2>&1 || \
   plutil -extract entities.JobScope.fields.aiExtractionDrafts json -o - "$BASELINE_SCHEMA" >/dev/null 2>&1; then
  fail "pinned baseline unexpectedly contains the candidate AI fields"
fi

baseline_schema_version="$(plutil -extract version raw -o - "$BASELINE_SCHEMA" 2>/dev/null)" || \
  fail "pinned baseline schema version is unavailable"
current_schema_version="$(plutil -extract version raw -o - "$CURRENT_SCHEMA" 2>/dev/null)" || \
  fail "current schema version is unavailable"
[[ "$baseline_schema_version" =~ ^[0-9]+$ ]] || fail "pinned baseline schema version is invalid"
[[ "$current_schema_version" =~ ^[0-9]+$ ]] || fail "current schema version is invalid"
(( current_schema_version >= baseline_schema_version )) || \
  fail "current schema version is older than the pinned baseline"

assert_schema_value entities.JobScope.fields.voiceNotes.type array
assert_schema_value entities.JobScope.fields.voiceNotes.items ScopeVoiceNote
assert_schema_value entities.JobScope.fields.voiceNotes.required false
assert_schema_value entities.JobScope.fields.aiExtractionDrafts.type array
assert_schema_value entities.JobScope.fields.aiExtractionDrafts.items ScopeAIExtractionDraft
assert_schema_value entities.JobScope.fields.aiExtractionDrafts.required false
assert_schema_value types.ScopeVoiceNote.fields.audioPath.type string
assert_schema_value types.ScopeVoiceNote.fields.transcriptStatus.type enum
assert_schema_value types.ScopeAIExtractionDraft.fields.suggestedFields.items ScopeAIFieldSuggestion
assert_schema_value types.ScopeAIFieldSuggestion.fields.confidence.type enum

touch "$TEST_TMP/.persistence-harness-sentinel"

xcrun swiftc \
  -parse-as-library \
  -module-cache-path "$TEST_TMP/BaselineModuleCache" \
  "$BASELINE_MODEL" \
  "$SUPPORT_FILE" \
  "$FIXTURE_VALUES_FILE" \
  "$PATH_GUARD_FILE" \
  "$BASELINE_WRITER_SOURCE" \
  -o "$TEST_TMP/baseline-writer"

xcrun swiftc \
  -parse-as-library \
  -module-cache-path "$TEST_TMP/CurrentModuleCache" \
  "$CURRENT_MODEL" \
  "$SUPPORT_FILE" \
  "$FIXTURE_VALUES_FILE" \
  "$PATH_GUARD_FILE" \
  "$CURRENT_VERIFIER_SOURCE" \
  -o "$TEST_TMP/current-verifier"

STORE_PATH="$TEST_TMP/Compatibility.store"
REJECTED_DIR="$TEST_TMP/rejected-path"
REJECTED_STORE_PATH="$REJECTED_DIR/Compatibility.store"
mkdir -p "$REJECTED_DIR"
if "$TEST_TMP/baseline-writer" "$REJECTED_STORE_PATH" >/dev/null 2>&1; then
  fail "baseline writer accepted a store outside the harness-owned directory"
fi
for rejected_artifact in \
  "$REJECTED_STORE_PATH" \
  "$REJECTED_STORE_PATH-wal" \
  "$REJECTED_STORE_PATH-shm"; do
  [[ ! -e "$rejected_artifact" && ! -L "$rejected_artifact" ]] || \
    fail "rejected store path produced an artifact"
done

DANGLING_TARGET="$TEST_TMP/dangling-target.store"
ln -s "$DANGLING_TARGET" "$STORE_PATH" || \
  fail "dangling-symlink containment fixture could not be created"
if "$TEST_TMP/baseline-writer" "$STORE_PATH" >/dev/null 2>&1; then
  fail "baseline writer accepted a dangling store symlink"
fi
[[ ! -e "$DANGLING_TARGET" && ! -L "$DANGLING_TARGET" ]] || \
  fail "dangling store symlink created its target"
unlink "$STORE_PATH" || fail "dangling-symlink containment fixture could not be removed"

"$TEST_TMP/baseline-writer" "$STORE_PATH"
PRISTINE_DIR="$TEST_TMP/PristineBaseline"
PRISTINE_STORE_PATH="$PRISTINE_DIR/Compatibility.store"
mkdir -p "$PRISTINE_DIR"
cp -p "$STORE_PATH" "$PRISTINE_STORE_PATH" || \
  fail "pristine baseline store could not be preserved"
for sqlite_companion_suffix in -wal -shm; do
  if [[ -f "${STORE_PATH}${sqlite_companion_suffix}" ]]; then
    cp -p \
      "${STORE_PATH}${sqlite_companion_suffix}" \
      "${PRISTINE_STORE_PATH}${sqlite_companion_suffix}" || \
      fail "pristine baseline store companion could not be preserved"
  fi
done
"$TEST_TMP/current-verifier" "$STORE_PATH" upgrade
"$TEST_TMP/current-verifier" "$STORE_PATH" verify

echo "Persistence compatibility verification passed"
