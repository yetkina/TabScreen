#!/bin/zsh
# Builds TabScreen.app into ./build (no Xcode project needed, just the Swift toolchain).
set -euo pipefail
cd "$(dirname "$0")"

APP="build/TabScreen.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" build/icon.iconset

echo "› Compiling…"
swiftc -O -swift-version 5 -parse-as-library \
  -target arm64-apple-macos13.0 \
  Sources/*.swift -o "$APP/Contents/MacOS/TabScreen"

echo "› Icon…"
swift Tools/make_icon.swift build/icon_1024.png
for s in 16 32 128 256 512; do
  sips -z $s $s build/icon_1024.png --out build/icon.iconset/icon_${s}x${s}.png >/dev/null
  sips -z $((s*2)) $((s*2)) build/icon_1024.png --out build/icon.iconset/icon_${s}x${s}@2x.png >/dev/null
done
iconutil -c icns build/icon.iconset -o "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>TabScreen</string>
  <key>CFBundleDisplayName</key><string>TabScreen</string>
  <key>CFBundleIdentifier</key><string>app.tabscreen.helper</string>
  <key>CFBundleExecutable</key><string>TabScreen</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleLocalizations</key><array><string>en</string><string>tr</string></array>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST

codesign --force --deep -s - "$APP" >/dev/null 2>&1 || true
echo "✓ Built $APP"
