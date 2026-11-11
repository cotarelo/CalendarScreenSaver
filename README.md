# CalendarScreenSaver

Salvapantallas para macOS con los eventos de hoy de Calendario en dos columnas:
**Trabajo** (cuentas Exchange/Outlook, en rojo) a la izquierda y **Personal** (el resto, p. ej. Google Calendar, en azul) a la derecha. El reloj lo sigue mostrando macOS.

## Componentes

- `saver/`: el salvapantallas (`CalendarScreenSaver.saver`). No puede pedir acceso a Calendario, así que lee `/Users/Shared/FractalAgenda/agenda.json`. Muestra solo los eventos que aún no han terminado, una columna por calendario.
- `agenda/`: el ayudante `FractalAgenda.app`. Tiene permiso de Calendario, lee los eventos de hoy y escribe `/Users/Shared/FractalAgenda/agenda.json` (carpeta solo legible por tu usuario).

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

## Permisos de Calendario

El ayudante necesita acceso a Calendario una sola vez. Después:

- **Ya no debería volver a pedirlo.** `agenda/build.sh` firma el ayudante con un requisito basado en el identificador `local.fractalagenda`, no en el hash del binario. Así el permiso sobrevive a recompilaciones y reinstalaciones.
- **No existe "permitir siempre" para apps sin firma de desarrollador.** La firma ad hoc no permite un permiso permanente explícito. Lo que sí funciona es conservar el identificador y la firma estable, que es lo que hace el script.
- **Si macOS vuelve a pedirlo** (por ejemplo, tras cambiar de Mac o de firma), concédelo otra vez en Ajustes → Privacidad y seguridad → Calendarios.
- **Si lo quitaste de la lista**, vuelve a abrir `~/Applications/FractalAgenda.app` para que aparezca el aviso.

## Asignación de calendarios

- Trabajo: calendarios de cuentas Exchange, excepto los que contienen "festivo", "cumplea", "birthday" o "holiday".
- Personal: el resto de calendarios.

## Permiso "Datos de otras apps"

El ayudante escribe en `/Users/Shared/FractalAgenda/`, no en el contenedor del salvapantallas. Así macOS no le pide el permiso de "datos de otras apps". Si aún así aparece el aviso, concédelo una vez con **Permitir**.
