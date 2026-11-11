#!/bin/bash
# Compila CalendarScreenSaver.saver (sin Xcode, con el toolchain de swift) y lo firma ad hoc.
set -euo pipefail
cd "$(dirname "$0")"
BUNDLE="CalendarScreenSaver.saver"
rm -rf "$BUNDLE"
mkdir -p "$BUNDLE/Contents/MacOS"
cp Info.plist "$BUNDLE/Contents/Info.plist"
swiftc -O -swift-version 5 -parse-as-library \
  -module-name CalendarScreenSaver \
  -Xlinker -bundle \
  -framework ScreenSaver -framework AppKit -framework EventKit \
  CalendarScreenSaverView.swift \
  -o "$BUNDLE/Contents/MacOS/CalendarScreenSaver"
codesign --force --sign - "$BUNDLE"
echo "Built: $(pwd)/$BUNDLE"
