#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/app"

BLOCKERS=0
WARNINGS=0

pass() {
  printf '[PASS] %s\n' "$1"
}

warn() {
  printf '[WARN] %s\n' "$1"
  WARNINGS=$((WARNINGS + 1))
}

fail() {
  printf '[FAIL] %s\n' "$1"
  BLOCKERS=$((BLOCKERS + 1))
}

exists() {
  [ -f "$1" ]
}

contains() {
  local pattern="$1"
  shift
  if command -v rg >/dev/null 2>&1; then
    rg -q "$pattern" "$@"
  else
    grep -Eq "$pattern" "$@"
  fi
}

check_file() {
  local path="$1"
  local label="$2"
  if exists "$path"; then
    pass "$label"
  else
    fail "$label ($path)"
  fi
}

check_warn_file() {
  local path="$1"
  local label="$2"
  if exists "$path"; then
    pass "$label present"
  else
    warn "$label missing ($path)"
  fi
}

echo '=== Luma P1 Release Readiness Check ==='

check_file "$ROOT_DIR/legal/privacy_policy.md" "Privacy policy exists"
check_file "$ROOT_DIR/legal/terms_of_service.md" "Terms of service exists"
check_file "$ROOT_DIR/docs/reports/app_store_play_console_ops_checklist.md" "Store console checklist exists"
check_file "$ROOT_DIR/docs/reports/p1_release_readiness.md" "P1 readiness plan exists"
check_file "$ROOT_DIR/docs/reports/store_listing_copy_template.md" "Store listing copy template exists"

if contains 'namespace = "ai\.luma\.app"' "$APP_DIR/android/app/build.gradle.kts" &&
  contains 'applicationId = "ai\.luma\.app"' "$APP_DIR/android/app/build.gradle.kts"; then
  pass "Android package id configured as ai.luma.app"
else
  fail "Android package id is not fully configured as ai.luma.app"
fi

if contains 'PRODUCT_BUNDLE_IDENTIFIER = ai\.luma\.app;' "$APP_DIR/ios/Runner.xcodeproj/project.pbxproj"; then
  pass "iOS bundle id configured as ai.luma.app"
else
  fail "iOS bundle id is not configured as ai.luma.app"
fi

if contains 'support@your-domain\.com' \
  "$ROOT_DIR/legal/privacy_policy.md" \
  "$ROOT_DIR/legal/terms_of_service.md"; then
  fail "Legal documents still use placeholder support email: support@your-domain.com"
else
  pass "Legal documents use a non-placeholder support email"
fi

check_warn_file "$APP_DIR/android/key.properties" "Android release signing config"
check_warn_file "$APP_DIR/android/app/google-services.json" "Android Firebase config"
check_warn_file "$APP_DIR/ios/Runner/GoogleService-Info.plist" "iOS Firebase config"

if [ "${RUN_FLUTTER_CHECKS:-0}" = "1" ]; then
  echo '--- Running flutter analyze ---'
  (
    cd "$APP_DIR"
    flutter analyze
  ) || fail "flutter analyze failed"

  echo '--- Running core regression suite ---'
  (
    cd "$APP_DIR"
    HTTP_PROXY= HTTPS_PROXY= ALL_PROXY= NO_PROXY=127.0.0.1,localhost,::1 \
    http_proxy= https_proxy= all_proxy= no_proxy=127.0.0.1,localhost,::1 \
    flutter test \
      test/integration/app_flow_test.dart \
      test/features/onboarding_test.dart \
      test/features/settings_screen_test.dart \
      test/features/chat_warning_test.dart
  ) || fail "core regression suite failed"
else
  warn "Flutter checks skipped. Re-run with RUN_FLUTTER_CHECKS=1 for analyze and core regression."
fi

echo "--- Summary: blockers=$BLOCKERS warnings=$WARNINGS ---"

if [ "$BLOCKERS" -gt 0 ]; then
  exit 1
fi
