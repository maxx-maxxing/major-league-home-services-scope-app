#!/usr/bin/env bash
set -euo pipefail
umask 077

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_FILE="${PROJECT_DIR}/ConstructionScopeApp.xcodeproj"
SCHEME_FILE="${PROJECT_FILE}/xcshareddata/xcschemes/ConstructionScopeApp.xcscheme"
TEST_TMP="$(mktemp -d /tmp/scope-jobtread-security.XXXXXX)"

cleanup() {
  rm -rf "$TEST_TMP"
}
trap cleanup EXIT

fail() {
  echo "JobTread security verification failed: $1" >&2
  exit 1
}

reject_rg_match() {
  local match_message="$1"
  shift
  local status
  if rg "$@" >/dev/null; then
    fail "$match_message"
  else
    status=$?
    [[ "$status" -eq 1 ]] || fail "source scan could not complete: $match_message"
  fi
}

require_rg_match() {
  local missing_message="$1"
  shift
  local status
  if rg "$@" >/dev/null; then
    return
  else
    status=$?
    [[ "$status" -eq 1 ]] || fail "source scan could not complete: $missing_message"
    fail "$missing_message"
  fi
}

reject_grep_match() {
  local match_message="$1"
  shift
  local status
  if LC_ALL=C grep "$@" >/dev/null 2>&1; then
    fail "$match_message"
  else
    status=$?
    [[ "$status" -eq 1 ]] || fail "artifact scan could not complete: $match_message"
  fi
}

compile_and_run_tests() {
  local mode="$1"
  local binary="$TEST_TMP/jobtread-security-${mode}"
  local module_cache="$TEST_TMP/ModuleCache-${mode}"
  if [[ "$mode" == "debug" ]]; then
    xcrun swiftc \
      -D DEBUG \
      -module-cache-path "$module_cache" \
      "$PROJECT_DIR/Services/JobTreadConfig.swift" \
      "$PROJECT_DIR/SecurityTests/JobTreadClientTestSupport.swift" \
      "$PROJECT_DIR/Services/JobTreadClient.swift" \
      "$PROJECT_DIR/SecurityTests/JobTreadSecurityTests.swift" \
      -o "$binary"
  else
    xcrun swiftc \
      -module-cache-path "$module_cache" \
      "$PROJECT_DIR/Services/JobTreadConfig.swift" \
      "$PROJECT_DIR/SecurityTests/JobTreadClientTestSupport.swift" \
      "$PROJECT_DIR/Services/JobTreadClient.swift" \
      "$PROJECT_DIR/SecurityTests/JobTreadSecurityTests.swift" \
      -o "$binary"
  fi
  "$binary"
}

verify_source_privacy() {
  local -a inspected_files=(
    "$PROJECT_DIR/Services/JobTreadClient.swift"
    "$PROJECT_DIR/Features/JobTreadCustomerSelection.swift"
    "$PROJECT_DIR/Views/RootNavigationView.swift"
    "$PROJECT_DIR/Views/SectionEditors.swift"
    "$PROJECT_DIR/Views/JobTreadDebugView.swift"
  )

  reject_rg_match "console output remains in an inspected JobTread path" \
    -n '\b(print|debugPrint|dump|NSLog)\s*\(' "${inspected_files[@]}"
  reject_rg_match "an interpolated error remains in a diagnostic sink within an inspected JobTread path" \
    -n '(assertionFailure|preconditionFailure|fatalError)\([^\n]*\\\([^\n]*(error|localizedDescription)' \
    "${inspected_files[@]}"
  reject_rg_match "a sensitive value is interpolated into an inspected JobTread Logger call" \
    -U -n '(?s)\b(?:Self\.)?logger\.(?:trace|debug|info|notice|warning|error|critical)\(.{0,400}?\\\([^)]*(?:[Qq]uery|attempt\.value|customerID|scopeID|grantKey|apiKey|organizationID|customer\.name|linkedCustomerName|user\.name|organization\.name|address|email|phone|localizedDescription|response|body|\.message)' \
    "${inspected_files[@]}"
  reject_rg_match "raw response or API-message propagation remains in JobTreadClient" \
    -n 'unexpectedStatusCode\([^\n]*body:|String\s*\(\s*data:\s*data|apiErrors\(\[String\]\)|messages\.joined' \
    "$PROJECT_DIR/Services/JobTreadClient.swift"
  reject_rg_match "Release configuration includes the ignored local secret override" \
    -n 'JobTreadSecrets\.xcconfig' "$PROJECT_DIR/Config/AppConfig.Release.xcconfig"
  reject_rg_match "Release Info.plist contains direct JobTread keys" \
    -n 'JOBTREAD_' "$PROJECT_DIR/ConstructionScopeApp-Release-Info.plist"
  require_rg_match "Release configuration does not include the checked-in safe defaults" \
    -n '^#include "AppConfig\.xcconfig"$' "$PROJECT_DIR/Config/AppConfig.Release.xcconfig"

  local key
  for key in JOBTREAD_API_KEY JOBTREAD_ORG_ID JOBTREAD_API_BASE_URL; do
    require_rg_match "the checked-in default for $key is not explicitly empty" \
      -n "^${key}[[:space:]]*=[[:space:]]*$" "$PROJECT_DIR/Config/AppConfig.xcconfig"
  done
}

verify_release_build_settings() {
  local archive_status
  if rg -U '<ArchiveAction\s+buildConfiguration = "Release"' "$SCHEME_FILE" >/dev/null; then
    :
  else
    archive_status=$?
    [[ "$archive_status" -eq 1 ]] || fail "the shared scheme could not be inspected"
    fail "the shared scheme Archive action is not pinned to Release"
  fi

  local settings_file="$TEST_TMP/release-build-settings.txt"
  xcodebuild -project "$PROJECT_FILE" \
    -scheme ConstructionScopeApp \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    CODE_SIGNING_ALLOWED=NO \
    -showBuildSettings >"$settings_file"

  if rg 'SWIFT_ACTIVE_COMPILATION_CONDITIONS.*DEBUG' "$settings_file" >/dev/null; then
    fail "Release enables the DEBUG compilation condition"
  else
    local debug_condition_status=$?
    [[ "$debug_condition_status" -eq 1 ]] || fail "Release compilation conditions could not be inspected"
  fi

  local direct_settings_file="$TEST_TMP/release-direct-settings.txt"
  local settings_status
  if rg '^[[:space:]]*JOBTREAD_(API_KEY|ORG_ID|API_BASE_URL)[[:space:]]*=' \
    "$settings_file" >"$direct_settings_file"; then
    :
  else
    settings_status=$?
    [[ "$settings_status" -eq 1 ]] || fail "Release JobTread build settings could not be inspected"
  fi

  local key value
  while IFS='=' read -r key value; do
    key="${key#"${key%%[![:space:]]*}"}"
    key="${key%"${key##*[![:space:]]}"}"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    case "$key" in
      JOBTREAD_API_KEY)
        [[ -z "$value" ]] || fail "Release resolves a nonempty direct JobTread setting"
        ;;
      JOBTREAD_ORG_ID)
        [[ -z "$value" ]] || fail "Release resolves a nonempty direct JobTread setting"
        ;;
      JOBTREAD_API_BASE_URL)
        [[ -z "$value" ]] || fail "Release resolves a nonempty direct JobTread setting"
        ;;
    esac
  done <"$direct_settings_file"
}

verify_release_artifact() {
  local derived_data="$TEST_TMP/DerivedData"
  local secret_sentinel="JT_SECRET_SENTINEL_7E5A1C"
  local org_sentinel="JT_ORG_SENTINEL_7E5A1C"
  local url_sentinel="https://jt-sentinel.invalid/pave"

  xcodebuild -quiet \
    -project "$PROJECT_FILE" \
    -scheme ConstructionScopeApp \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    -derivedDataPath "$derived_data" \
    CODE_SIGNING_ALLOWED=NO \
    JOBTREAD_API_KEY="$secret_sentinel" \
    JOBTREAD_ORG_ID="$org_sentinel" \
    JOBTREAD_API_BASE_URL="$url_sentinel" \
    build

  local app="$derived_data/Build/Products/Release-iphoneos/ConstructionScopeApp.app"
  local plist="$app/Info.plist"
  [[ -d "$app" ]] || fail "Release app artifact was not produced"
  [[ -f "$plist" ]] || fail "Release app Info.plist was not produced"

  local key
  for key in JOBTREAD_API_KEY JOBTREAD_ORG_ID JOBTREAD_API_BASE_URL; do
    if /usr/libexec/PlistBuddy -c "Print :$key" "$plist" >/dev/null 2>&1; then
      fail "Release app contains a direct JobTread Info.plist key"
    fi
  done

  local marker
  for marker in "$secret_sentinel" "$org_sentinel" "$url_sentinel"; do
    reject_grep_match "Release app contains an injected JobTread sentinel" \
      -R -a -F -q -- "$marker" "$app"
  done

  local bundled_secret_file
  if ! bundled_secret_file="$(find "$app" -name 'JobTreadSecrets.xcconfig' -print -quit)"; then
    fail "Release app could not be inspected for the ignored JobTread secret file"
  fi
  [[ -z "$bundled_secret_file" ]] || fail "Release app contains the ignored JobTread secret file"

  local local_override="$PROJECT_DIR/Config/JobTreadSecrets.xcconfig"
  if [[ -f "$local_override" ]]; then
    local config_key=""
    local config_value=""
    local pattern_file="$TEST_TMP/local-override-pattern"
    local tracked_files_file="$TEST_TMP/tracked-files"
    local tracked_file
    if ! git -C "$PROJECT_DIR" ls-files -z >"$tracked_files_file"; then
      fail "tracked source files could not be enumerated for the local-value scan"
    fi

    while IFS='=' read -r config_key config_value || [[ -n "${config_key}${config_value}" ]]; do
      config_key="${config_key#"${config_key%%[![:space:]]*}"}"
      config_key="${config_key%"${config_key##*[![:space:]]}"}"
      config_value="${config_value#"${config_value%%[![:space:]]*}"}"
      config_value="${config_value%"${config_value##*[![:space:]]}"}"
      case "$config_key" in
        JOBTREAD_API_KEY|JOBTREAD_ORG_ID|JOBTREAD_API_BASE_URL)
          if [[ -n "$config_value" && "$config_value" != *'$('* ]]; then
            printf '%s\n' "$config_value" >"$pattern_file"
            reject_grep_match "Release app contains a value from the ignored local JobTread override" \
              -R -a -F -q -f "$pattern_file" -- "$app"
            while IFS= read -r -d '' tracked_file; do
              [[ -f "$PROJECT_DIR/$tracked_file" ]] || fail "a tracked source file could not be inspected"
              reject_grep_match "tracked source contains a value from the ignored local JobTread override" \
                -a -F -q -f "$pattern_file" -- "$PROJECT_DIR/$tracked_file"
            done <"$tracked_files_file"
          fi
          ;;
      esac
      config_key=""
      config_value=""
    done <"$local_override"
  fi
}

compile_and_run_tests debug
compile_and_run_tests release
verify_source_privacy
verify_release_build_settings
verify_release_artifact

echo "JobTread security verification passed"
