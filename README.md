# CalendarScreenSaver

Salvapantallas para macOS con los eventos de hoy de Calendario en dos columnas:
**Trabajo** (cuentas Exchange/Outlook, en rojo) a la izquierda y **Personal** (el resto, p. ej. Google Calendar, en azul) a la derecha. El reloj lo sigue mostrando macOS.

## Componentes

- `saver/`: el salvapantallas (`CalendarScreenSaver.saver`). No puede pedir acceso a Calendario, así que lee `agenda.json`.
- `agenda/`: el ayudante `FractalAgenda.app`. Tiene permiso de Calendario, lee los eventos de hoy y escribe `agenda.json` en el contenedor del salvapantallas.

## Compilar

Requiere las herramientas de línea de comandos de Xcode (`swiftc`) y macOS 14 o posterior. Los scripts compilan binarios universales (Apple Silicon e Intel). Los scripts compilan binarios universales (Apple Silicon e Intel).

```bash
cd saver && ./build.sh
cp -R CalendarScreenSaver.saver ~/Library/Screen\ Savers/
cd ../agenda && ./build.sh && ./install-agent.sh
```

Después abre `~/Applications/FractalAgenda.app` una vez y concede el acceso a Calendario en Ajustes → Privacidad y seguridad → Calendarios.

## ⚠️ Actualización automática (MUY IMPORTANTE)

**Sin este paso, los eventos nunca se actualizan y el salvapantallas muestra datos antiguos.**

Ejecuta `agenda/install-agent.sh` después de compilar el ayudante. Instala `FractalAgenda.app` en `~/Applications` y crea el LaunchAgent `local.fractalagenda`, que lo ejecuta cada 30 minutos (`StartInterval` 1800) y al iniciar sesión.

Para desactivarlo:

```bash
launchctl bootout gui/$(id -u)/local.fractalagenda && rm ~/Library/LaunchAgents/local.fractalagenda.plist
```

## Asignación de calendarios

- Trabajo: calendarios de cuentas Exchange, excepto los que contienen "festivo", "cumplea", "birthday" o "holiday".
- Personal: el resto de calendarios.
