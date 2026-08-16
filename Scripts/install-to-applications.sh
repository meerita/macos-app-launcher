#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED_DATA_PATH="$ROOT_DIR/.derivedData"
BUILT_APP="$DERIVED_DATA_PATH/Build/Products/Release/macos-app-launcher.app"
INSTALLED_APP="/Applications/App Launcher.app"

xcodebuild \
  -project "$ROOT_DIR/macos-app-launcher.xcodeproj" \
  -scheme macos-app-launcher \
  -configuration Release \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  build

rm -rf "$INSTALLED_APP"
ditto "$BUILT_APP" "$INSTALLED_APP"
open "$INSTALLED_APP"
