#!/usr/bin/env bash
# Build a Release DMG for GitHub Releases (ad-hoc signed unless you set DEVELOPER_ID).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:-1.1.1}"
cd "$ROOT"
xcodegen generate
xcodebuild -project VoltPeek.xcodeproj -scheme VoltPeek -configuration Release \
  -destination 'platform=macOS' -derivedDataPath build/DerivedData \
  CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY:--}" CODE_SIGNING_ALLOWED=YES \
  build
APP="$ROOT/build/DerivedData/Build/Products/Release/VoltPeek.app"
STAGE="$ROOT/build/dmg-stage"
OUT="$ROOT/build/VoltPeek-${VERSION}.dmg"
rm -rf "$STAGE" "$OUT"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "VoltPeek" -srcfolder "$STAGE" -ov -format UDZO "$OUT"
shasum -a 256 "$OUT"
echo "DMG ready: $OUT"
