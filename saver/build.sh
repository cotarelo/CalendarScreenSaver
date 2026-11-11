#!/bin/bash
# Compila CalendarScreenSaver.saver como binario universal (Apple Silicon + Intel) y lo firma ad hoc.
set -euo pipefail
cd "$(dirname "$0")"
BUNDLE="CalendarScreenSaver.saver"
MIN_OS="14.0"
rm -rf "$BUNDLE"
mkdir -p "$BUNDLE/Contents/MacOS"
cp Info.plist "$BUNDLE/Contents/Info.plist"

for ARCH in arm64 x86_64; do
  swiftc -O -swift-version 5 -parse-as-library \
    -target "$ARCH-apple-macos$MIN_OS" \
    -module-name CalendarScreenSaver \
    -Xlinker -bundle \
    -framework ScreenSaver -framework AppKit -framework EventKit \
    CalendarScreenSaverView.swift \
    -o "build-$ARCH"
done

lipo -create build-arm64 build-x86_64 -output "$BUNDLE/Contents/MacOS/CalendarScreenSaver"
rm -f build-arm64 build-x86_64
codesign --force --sign - "$BUNDLE"
echo "Built: $(pwd)/$BUNDLE"
lipo -info "$BUNDLE/Contents/MacOS/CalendarScreenSaver"
