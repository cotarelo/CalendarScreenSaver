import Foundation
import EventKit

// Ayudante: lee los eventos de hoy de Calendario (con permiso propio) y escribe
// un JSON que el salvapantallas lee desde su contenedor.

let fm = FileManager.default
let home = fm.homeDirectoryForCurrentUser
// Carpeta compartida (sin la protección de "datos de otras apps"), con permisos solo para el usuario.
let outDir = URL(fileURLWithPath: "/Users/Shared/FractalAgenda")
let outURL = outDir.appendingPathComponent("agenda.json")
try? fm.createDirectory(at: outDir, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
try? fm.setAttributes([.posixPermissions: 0o700], ofItemAtPath: outDir.path)

let store = EKEventStore()
let sem = DispatchSemaphore(value: 0)
var granted = false
store.requestFullAccessToEvents { ok, _ in
    granted = ok
    sem.signal()
}
sem.wait()

func write(_ object: [String: Any]) {
    if let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]) {
        try? data.write(to: outURL, options: .atomic)
        try? fm.setAttributes([.posixPermissions: 0o600], ofItemAtPath: outURL.path)
    }
}

let isoFormatter = ISO8601DateFormatter()
let timeFormatter = DateFormatter()
timeFormatter.locale = Locale(identifier: "es_ES")
timeFormatter.dateFormat = "HH:mm"

guard granted else {
    write(["updated": isoFormatter.string(from: Date()), "error": "no_access"])
    print("Sin acceso a Calendario. Concédelo en Ajustes > Privacidad y seguridad > Calendarios.")
    exit(1)
}

let calendar = Calendar.current
let start = calendar.startOfDay(for: Date())
let end = calendar.date(byAdding: .day, value: 1, to: start)!
let all = store.calendars(for: .event)
// Trabajo = cuentas Exchange (Outlook), sin festivos ni cumpleaños.
// Todo lo demás (Google, iCloud, festivos, cumpleaños) va a personal.
let nonWorkNames = ["festivo", "cumplea", "birthday", "holiday"]
func isHolidayOrBirthday(_ c: EKCalendar) -> Bool {
    let t = c.title.lowercased()
    return nonWorkNames.contains { t.contains($0) }
}
let work = all.filter { $0.source?.sourceType == .exchange && !isHolidayOrBirthday($0) }
let personal = all.filter { !work.contains($0) }

func items(_ calendars: [EKCalendar]) -> [[String: Any]] {
    guard !calendars.isEmpty else { return [] }
    let predicate = store.predicateForEvents(withStart: start, end: end, calendars: calendars)
    // Se exportan todos los de hoy: el salvapantallas oculta los que ya han terminado.
    return store.events(matching: predicate)
        .sorted { $0.startDate < $1.startDate }
        .prefix(40)
        .map { e in
            [
                "time": e.isAllDay ? "Todo el día" : timeFormatter.string(from: e.startDate),
                "title": e.title ?? "(sin título)",
                "allDay": e.isAllDay,
                "start": isoFormatter.string(from: e.startDate),
                "end": isoFormatter.string(from: e.endDate)
            ]
        }
}

write([
    "updated": isoFormatter.string(from: Date()),
    "work": items(work),
    "personal": items(personal),
    "workCalendars": work.map { $0.title },
    "personalCalendars": personal.map { $0.title }
])
print("OK: trabajo=\(work.map { $0.title }) personal=\(personal.map { $0.title })")
