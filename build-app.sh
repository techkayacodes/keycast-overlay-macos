#!/usr/bin/env bash
# Builds a standalone clickable macOS app bundle: dist/KeycastOverlay.app
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT_DIR"

echo "Building keycast-overlay (release)..."
swift build -c release

BIN_PATH="$(swift build -c release --show-bin-path)/keycast-overlay"
APP_DIR="$ROOT_DIR/dist/KeycastOverlay.app"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$BIN_PATH" "$APP_DIR/Contents/MacOS/KeycastOverlay"
chmod +x "$APP_DIR/Contents/MacOS/KeycastOverlay"

cat > "$APP_DIR/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>KeycastOverlay</string>
  <key>CFBundleIdentifier</key>
  <string>io.github.techkayacodes.keycast-overlay</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>KeycastOverlay</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
EOF

echo "Built $APP_DIR"
echo "Double-click dist/KeycastOverlay.app or run: open dist/KeycastOverlay.app"
