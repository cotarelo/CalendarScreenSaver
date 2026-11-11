# CalendarScreenSaver

Salvapantallas para macOS con los eventos de hoy de Calendario en dos columnas:
**Trabajo** (cuentas Exchange/Outlook, en rojo) a la izquierda y **Personal** (el resto, p. ej. Google Calendar, en azul) a la derecha. El reloj lo sigue mostrando macOS.

## Componentes

- `saver/`: el salvapantallas (`CalendarScreenSaver.saver`). No puede pedir acceso a Calendario, así que lee `agenda.json`.
- `agenda/`: el ayudante `FractalAgenda.app`. Tiene permiso de Calendario, lee los eventos de hoy y escribe `agenda.json` en el contenedor del salvapantallas.

## Compilar

Requiere las herramientas de línea de comandos de Xcode (`swiftc`) y macOS 14 o posterior.

```bash
cd saver && ./build.sh
cp -R CalendarScreenSaver.saver ~/Library/Screen\ Savers/
cd ../agenda && ./build.sh
cp -R FractalAgenda.app ~/Applications/
```

Después abre `~/Applications/FractalAgenda.app` una vez y concede el acceso a Calendario.

## Actualización automática

Para refrescar los eventos cada 30 minutos, crea un LaunchAgent en `~/Library/LaunchAgents/` que ejecute `~/Applications/FractalAgenda.app/Contents/MacOS/FractalAgenda` con `StartInterval` 1800.

## Asignación de calendarios

- Trabajo: calendarios de cuentas Exchange, excepto los que contienen "festivo", "cumplea", "birthday" o "holiday".
- Personal: el resto de calendarios.
