#!/bin/zsh
# Builds, signs (Developer ID), notarizes and staples TabScreen, then produces a .dmg.
#
# One-time setup (see README):
#   1) A "Developer ID Application" certificate in your login keychain.
#   2) A notarytool profile:
#        xcrun notarytool store-credentials "tabscreen" \
#          --apple-id "<your Apple ID>" --team-id "<TEAM ID>" --password "<app-specific password>"
#
# Usage:  ./release.sh            (auto-detects the Developer ID identity)
#         IDENTITY="Developer ID Application: Name (TEAMID)" PROFILE=tabscreen ./release.sh
set -euo pipefail
cd "$(dirname "$0")"

PROFILE="${PROFILE:-tabscreen}"
APP="build/TabScreen.app"
VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' build/TabScreen.app/Contents/Info.plist 2>/dev/null || echo "1.0")

IDENTITY="${IDENTITY:-$(security find-identity -v -p codesigning | sed -n 's/.*"\(Developer ID Application:.*\)"/\1/p' | head -1)}"
if [[ -z "$IDENTITY" ]]; then
  echo "✗ No 'Developer ID Application' certificate found in your keychain."
  echo "  Create one in Xcode → Settings → Accounts → Manage Certificates → + → Developer ID Application."
  exit 1
fi
echo "› Identity: $IDENTITY"

./build.sh
VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist")

echo "› Signing (hardened runtime)…"
codesign --force --deep --options runtime --timestamp -s "$IDENTITY" "$APP"
codesign --verify --deep --strict --verbose=2 "$APP"

echo "› Notarizing (takes a few minutes)…"
ZIP="build/TabScreen-notarize.zip"
ditto -c -k --keepParent "$APP" "$ZIP"
xcrun notarytool submit "$ZIP" --keychain-profile "$PROFILE" --wait
xcrun stapler staple "$APP"
rm -f "$ZIP"

echo "› Building DMG…"
DMG="build/TabScreen-$VERSION.dmg"
rm -rf build/dmg "$DMG"
mkdir -p build/dmg
cp -R "$APP" build/dmg/
ln -s /Applications build/dmg/Applications
hdiutil create -volname "TabScreen" -srcfolder build/dmg -ov -format UDZO "$DMG" >/dev/null
codesign --force --timestamp -s "$IDENTITY" "$DMG"
xcrun notarytool submit "$DMG" --keychain-profile "$PROFILE" --wait
xcrun stapler staple "$DMG"

echo "✓ Done: $DMG"
spctl --assess --type open --context context:primary-signature -v "$DMG" || true
shasum -a 256 "$DMG"
