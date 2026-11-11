#!/bin/bash
# Construye FractalAgenda.app como binario universal (Apple Silicon + Intel) y lo firma ad hoc.
set -euo pipefail
cd "$(dirname "$0")"
APP="FractalAgenda.app"
MIN_OS="14.0"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp Info.plist "$APP/Contents/Info.plist"

for ARCH in arm64 x86_64; do
  swiftc -O -swift-version 5 main.swift \
    -target "$ARCH-apple-macos$MIN_OS" \
    -framework EventKit \
    -o "build-$ARCH"
done

lipo -create build-arm64 build-x86_64 -output "$APP/Contents/MacOS/FractalAgenda"
rm -f build-arm64 build-x86_64
codesign --force --sign - "$APP"
echo "Built: $(pwd)/$APP"
lipo -info "$APP/Contents/MacOS/FractalAgenda"
