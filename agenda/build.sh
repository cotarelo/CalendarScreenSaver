#!/bin/bash
# Construye FractalAgenda.app (ayudante que exporta los eventos de hoy) y lo firma ad hoc.
set -euo pipefail
cd "$(dirname "$0")"
APP="FractalAgenda.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp Info.plist "$APP/Contents/Info.plist"
swiftc -O -swift-version 5 main.swift -o "$APP/Contents/MacOS/FractalAgenda" -framework EventKit
codesign --force --sign - "$APP"
echo "Built: $(pwd)/$APP"
