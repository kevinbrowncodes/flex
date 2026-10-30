#!/usr/bin/env bash
# Regenerates every AppIcon PNG in the asset catalog from Support/FlexAppIcon.swift.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ICONSET="$ROOT/Flex/Flex/Assets.xcassets/AppIcon.appiconset"
BUILD="$(mktemp -d)"

swiftc -O "$ROOT/Flex/Flex/Support/FlexAppIcon.swift" "$ROOT/scripts/generate-app-icon/main.swift" -o "$BUILD/gen-icon"
"$BUILD/gen-icon" "$ICONSET/icon-1024.png"

for size in 20 29 40 58 60 76 80 87 120 152 167 180; do
  sips -s format png -z "$size" "$size" "$ICONSET/icon-1024.png" --out "$ICONSET/icon-$size.png" >/dev/null
done
echo "App icon regenerated in $ICONSET"
