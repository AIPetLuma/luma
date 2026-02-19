#!/usr/bin/env bash
# ============================================================
# setup_platform.sh — Configure Android/iOS platform files
#
# Run this AFTER `flutter create .` in the app/ directory.
# It adds required permissions and intent queries for:
#   - POST_NOTIFICATIONS (Android 13+)
#   - url_launcher queries (tel:, sms:)
#   - iOS LSApplicationQueriesSchemes
# ============================================================

set -euo pipefail

APP_DIR="$(cd "$(dirname "$0")/../app" && pwd)"

echo "=== Luma Platform Setup ==="
echo "App directory: $APP_DIR"

# ── Android ──

MANIFEST="$APP_DIR/android/app/src/main/AndroidManifest.xml"

if [ -f "$MANIFEST" ]; then
  echo ""
  echo "--- Android: Patching AndroidManifest.xml ---"

  # Add POST_NOTIFICATIONS permission if not present
  if ! grep -q 'POST_NOTIFICATIONS' "$MANIFEST"; then
    sed -i '/<manifest/a\    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>' "$MANIFEST"
    echo "  + Added POST_NOTIFICATIONS permission"
  else
    echo "  ~ POST_NOTIFICATIONS already present"
  fi

  # Add url_launcher queries if not present
  if ! grep -q 'android.intent.action.DIAL' "$MANIFEST"; then
    # Insert <queries> block before closing </manifest>
    sed -i '/<\/manifest>/i\
    <queries>\
        <intent>\
            <action android:name="android.intent.action.DIAL" />\
        </intent>\
        <intent>\
            <action android:name="android.intent.action.SENDTO" />\
        </intent>\
    </queries>' "$MANIFEST"
    echo "  + Added DIAL/SENDTO intent queries"
  else
    echo "  ~ Intent queries already present"
  fi

  echo "  Done."
else
  echo ""
  echo "WARNING: $MANIFEST not found."
  echo "  Run 'cd $APP_DIR && flutter create .' first to generate platform files."
fi

# ── iOS ──

PLIST="$APP_DIR/ios/Runner/Info.plist"

if [ -f "$PLIST" ]; then
  echo ""
  echo "--- iOS: Patching Info.plist ---"

  # Add LSApplicationQueriesSchemes if not present
  if ! grep -q 'LSApplicationQueriesSchemes' "$PLIST"; then
    # Insert before closing </dict>
    # Use Python for reliable plist editing
    python3 - "$PLIST" <<'PYEOF'
import plistlib, sys
path = sys.argv[1]
with open(path, 'rb') as f:
    plist = plistlib.load(f)
if 'LSApplicationQueriesSchemes' not in plist:
    plist['LSApplicationQueriesSchemes'] = ['tel', 'sms']
    with open(path, 'wb') as f:
        plistlib.dump(plist, f)
    print('  + Added LSApplicationQueriesSchemes (tel, sms)')
else:
    print('  ~ LSApplicationQueriesSchemes already present')
PYEOF
  else
    echo "  ~ LSApplicationQueriesSchemes already present"
  fi

  echo "  Done."
else
  echo ""
  echo "WARNING: $PLIST not found."
  echo "  Run 'cd $APP_DIR && flutter create .' first to generate platform files."
fi

# ── Firebase reminder ──

echo ""
echo "--- Firebase Config Reminder ---"
echo "  To enable push notifications, add:"
echo "    Android: $APP_DIR/android/app/google-services.json"
echo "    iOS:     $APP_DIR/ios/Runner/GoogleService-Info.plist"
echo "  Get these from the Firebase Console."
echo ""
echo "=== Setup complete ==="
