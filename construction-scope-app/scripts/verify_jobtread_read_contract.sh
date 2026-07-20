#!/usr/bin/env bash
set -euo pipefail
umask 077

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_TMP="$(mktemp -d /tmp/scope-jobtread-read-contract.XXXXXX)"

cleanup() {
  rm -rf -- "$TEST_TMP"
}
trap cleanup EXIT

fail() {
  echo "JobTread read contract verification failed: $1" >&2
  exit 1
}

verify_hash() {
  local expected="$1"
  local file="$2"
  local label="$3"
  local actual
  read -r actual _ < <(shasum -a 256 "$file")
  [[ "$actual" == "$expected" ]] || fail "$label changed outside the reviewed customer-read contract"
}

for required_tool in grep rg shasum xcrun; do
  command -v "$required_tool" >/dev/null 2>&1 || fail "required tool is unavailable: $required_tool"
done

CONFIG_SOURCE="$PROJECT_DIR/Services/JobTreadConfig.swift"
CLIENT_SOURCE="$PROJECT_DIR/Services/JobTreadClient.swift"
TEST_SUPPORT_SOURCE="$PROJECT_DIR/SecurityTests/JobTreadClientTestSupport.swift"
CONTRACT_TEST_SOURCE="$PROJECT_DIR/SecurityTests/JobTreadReadContractTests.swift"
PROJECT_FILE="$PROJECT_DIR/ConstructionScopeApp.xcodeproj/project.pbxproj"
MODEL_SOURCE="$PROJECT_DIR/Models/SchemaModels.swift"
SCHEMA_SOURCE="$PROJECT_DIR/schema.json"

for required_file in \
  "$CONFIG_SOURCE" \
  "$CLIENT_SOURCE" \
  "$TEST_SUPPORT_SOURCE" \
  "$CONTRACT_TEST_SOURCE" \
  "$PROJECT_FILE" \
  "$MODEL_SOURCE" \
  "$SCHEMA_SOURCE"; do
  [[ -f "$required_file" ]] || fail "required source file is unavailable"
done

verify_hash "93726a9233a2736bfb080bd7bbeeb45cfa3194d4bb3f19463482cf51208607e6" \
  "$CLIENT_SOURCE" "JobTread client source"
verify_hash "bdc920278104c86dda7ad4795e67ed8db395f1f9137ea72663000a1e06a5842c" \
  "$CONFIG_SOURCE" "JobTread configuration source"
verify_hash "cd2a6d3c74f7ec38d525bd78ad83f72ec9c18b03609f37942cfbc4c80e076e9b" \
  "$TEST_SUPPORT_SOURCE" "standalone JobTread test support"
verify_hash "f848b2307fa94c64e8efe8c31a0201950d2036f596a54dabfbf75aee8ddbaee8" \
  "$MODEL_SOURCE" "frozen SwiftData model"
verify_hash "819b1b81ea23d3600ae83c05e073843f5036811c524b73bc743235be88a447f4" \
  "$SCHEMA_SOURCE" "frozen schema"
verify_hash "3d00ac4003655406adb8f9002347b67c58995591260d710cbfd52da7114d8a45" \
  "$PROJECT_FILE" "Xcode project wiring"

grep -Fq 'https://jobtread-contract.invalid/pave' "$CONTRACT_TEST_SOURCE" || \
  fail "test transport is not pinned to the synthetic reserved endpoint"
grep -Fq 'configuration.protocolClasses = [OfflineURLProtocol.self]' "$CONTRACT_TEST_SOURCE" || \
  fail "test session does not install the offline URL protocol"
rg -U --pcre2 -q \
  '(?s)override class func canInit\(with request: URLRequest\) -> Bool\s*\{\s*true\s*\}' \
  "$CONTRACT_TEST_SOURCE" || fail "offline URL protocol does not unconditionally intercept requests"

if grep -Eq 'JobTreadSecrets|api\.jobtread\.com|JOBTREAD_API_KEY[[:space:]]*=|URLSession[.]shared' "$CONTRACT_TEST_SOURCE"; then
  fail "contract fixtures reference live configuration material"
fi

if grep -Fq 'JobTreadReadContractTests.swift' "$PROJECT_FILE"; then
  fail "contract tests were added to the app target"
fi

xcrun swiftc \
  -D DEBUG \
  -parse-as-library \
  -module-cache-path "$TEST_TMP/ModuleCache" \
  "$CONFIG_SOURCE" \
  "$TEST_SUPPORT_SOURCE" \
  "$CLIENT_SOURCE" \
  "$CONTRACT_TEST_SOURCE" \
  -o "$TEST_TMP/jobtread-read-contract-tests"

"$TEST_TMP/jobtread-read-contract-tests"

echo "JobTread read contract verification passed"
