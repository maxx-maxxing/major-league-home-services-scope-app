#!/usr/bin/env bash
set -euo pipefail
umask 077

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_TMP="$(mktemp -d /tmp/scope-backup-tests.XXXXXX)"
cleanup() {
  local status=$?
  if (( status == 0 )); then
    rm -rf -- "$TEST_TMP"
  else
    echo "Synthetic backup failure artifacts retained at: $TEST_TMP" >&2
  fi
}
trap cleanup EXIT
touch "$TEST_TMP/.scope-backup-harness"

python3 - "$PROJECT_DIR" <<'PY'
import json, pathlib, re, sys
root = pathlib.Path(sys.argv[1])
schema_version = json.loads((root / "schema.json").read_text())["version"]
archive = (root / "Persistence/ScopeBackupArchive.swift").read_text()
match = re.search(r"static let schemaVersion = (\d+)", archive)
assert match and int(match.group(1)) == schema_version, "backup schema version differs from authoritative schema.json"
project = (root / "ConstructionScopeApp.xcodeproj/project.pbxproj").read_text()
for name in ["ScopeBackupSimulatorSmoke.swift", "ScopeBackupTests.swift", "PersistenceFixtureValues.swift"]:
    assert name + " in Sources" not in project, "synthetic backup entry point/fixture is in the production target"
PY

# Extract production section identifiers needed by the review-state store.
# Fail closed if the bounded source region moves.
awk '
  /^enum ScopeSection:/ { copying = 1; starts++ }
  /^private enum ScopeSortOption:/ { copying = 0; ends++ }
  copying { print }
  END { if (starts != 1 || ends != 1) exit 1 }
' "$PROJECT_DIR/Views/RootNavigationView.swift" > "$TEST_TMP/ScopeSection.swift"

# No installed app store, user asset directory, credential/config override,
# network client, or simulator is opened. All stores and assets are synthetic.
xcrun swiftc \
  -parse-as-library \
  -warnings-as-errors \
  -module-cache-path "$TEST_TMP/ModuleCache" \
  "$PROJECT_DIR/Models/SchemaModels.swift" \
  "$PROJECT_DIR/PersistenceTests/JobTreadModelTestSupport.swift" \
  "$PROJECT_DIR/PersistenceTests/PersistenceFixtureValues.swift" \
  "$TEST_TMP/ScopeSection.swift" \
  "$PROJECT_DIR/Persistence/PersistenceSaveHealth.swift" \
  "$PROJECT_DIR/Persistence/Persistence.swift" \
  "$PROJECT_DIR/Models/ScopeBackupRecord.swift" \
  "$PROJECT_DIR/Persistence/ScopeBackupArchive.swift" \
  "$PROJECT_DIR/Persistence/ScopeBackupService.swift" \
  "$PROJECT_DIR/BackupTests/ScopeBackupTests.swift" \
  -o "$TEST_TMP/scope-backup-tests"

"$TEST_TMP/scope-backup-tests" "$TEST_TMP"
