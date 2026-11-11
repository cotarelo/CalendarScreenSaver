#!/bin/bash
# Instala FractalAgenda.app en ~/Applications y programa su LaunchAgent cada 30 minutos.
# Úsalo después de compilar el ayudante con ./build.sh (en esta misma carpeta).
set -euo pipefail
cd "$(dirname "$0")"

APP_SRC="FractalAgenda.app"
APP_DST="$HOME/Applications/FractalAgenda.app"
LABEL="local.fractalagenda"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"

if [ ! -d "$APP_SRC" ]; then
  echo "Falta $APP_SRC. Ejecuta antes ./build.sh"
  exit 1
fi

mkdir -p "$HOME/Applications" "$HOME/Library/LaunchAgents"
rm -rf "$APP_DST"
cp -R "$APP_SRC" "$APP_DST"

cat > "$PLIST" <<PLISTEOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>$LABEL</string>
	<key>ProgramArguments</key>
	<array>
		<string>$APP_DST/Contents/MacOS/FractalAgenda</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
	<key>StartInterval</key>
	<integer>1800</integer>
</dict>
</plist>
PLISTEOF
plutil -lint "$PLIST"

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"

echo "Instalado. Primera ejecución: abre $APP_DST una vez y concede acceso a Calendario."
echo "Se actualizará cada 30 minutos."
