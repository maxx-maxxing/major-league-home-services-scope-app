#!/usr/bin/env bash
set -euo pipefail
umask 077

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_TMP="$(mktemp -d /tmp/scope-proposal-measurements.XXXXXX)"
trap 'rm -rf -- "$TEST_TMP"' EXIT

# Use production visibility rules without compiling SwiftUI views. Fail if the
# bounded source region moves, rather than using a duplicate hard-coded map.
awk '
  /^enum ScopeSection:/ { copying = 1; starts++ }
  /^private enum ScopeSortOption:/ { copying = 0; ends++ }
  copying { print }
  END { if (starts != 1 || ends != 1) exit 1 }
' "$PROJECT_DIR/Views/RootNavigationView.swift" > "$TEST_TMP/ScopeSection.swift"

# Compile the actual model/builder. No store is opened, app launched, real
# attachments enumerated, secret override read, or network client included.
xcrun swiftc \
  -parse-as-library \
  -warnings-as-errors \
  -module-cache-path "$TEST_TMP/ModuleCache" \
  "$PROJECT_DIR/Models/SchemaModels.swift" \
  "$PROJECT_DIR/PersistenceTests/JobTreadModelTestSupport.swift" \
  "$TEST_TMP/ScopeSection.swift" \
  "$PROJECT_DIR/Models/PricingProposalFoundation.swift" \
  "$PROJECT_DIR/ProposalTests/ProposalMeasurementTests.swift" \
  -o "$TEST_TMP/proposal-measurement-tests"

"$TEST_TMP/proposal-measurement-tests"
