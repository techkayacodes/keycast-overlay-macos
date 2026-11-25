#!/usr/bin/env bash
# Builds and installs KeycastOverlay.app into /Applications and the CLI binary into /usr/local/bin
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
"$ROOT_DIR/build-app.sh"

echo "Installing KeycastOverlay.app to /Applications..."
rm -rf /Applications/KeycastOverlay.app
cp -R "$ROOT_DIR/dist/KeycastOverlay.app" /Applications/KeycastOverlay.app

echo "Done! Launch KeycastOverlay from Applications or Spotlight."
echo "Note: Grant Accessibility permission in System Settings -> Privacy & Security -> Accessibility."
