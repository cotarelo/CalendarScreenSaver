import ScreenSaver
import AppKit

/// Salvapantallas: fondo negro, fecha arriba y dos columnas con los eventos de hoy.
/// Trabajo (rojo) a la izquierda, personal (azul tipo Google Calendar) a la derecha.
/// Solo se muestran los eventos que aún no han terminado.
///
/// Los eventos los escribe el ayudante FractalAgenda en /Users/Shared/FractalAgenda/agenda.json
/// (este proceso no puede pedir acceso a Calendario).
@objc(CalendarScreenSaverView)
class CalendarScreenSaverView: ScreenSaverView {

    private struct AgendaItem {
        let time: String
        let title: String
        let allDay: Bool
        let end: Date?
    }

    private var work: [AgendaItem] = []
    private var personal: [AgendaItem] = []
    private var statusMessage: String?
    private var lastLoad = Date.distantPast
    private let locale = Locale(identifier: "es_ES")
    private let workColor = NSColor(calibratedRed: 1.0, green: 0.23, blue: 0.19, alpha: 1.0)      // rojo
    private let personalColor = NSColor(calibratedRed: 0.10, green: 0.45, blue: 0.91, alpha: 1.0) // azul Google

    private let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        return f
    }()

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        animationTimeInterval = 1.0
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        animationTimeInterval = 1.0
    }

    override func startAnimation() {
        super.startAnimation()
        loadAgenda()
    }

    override func animateOneFrame() {
        if Date().timeIntervalSince(lastLoad) > 30 {
            loadAgenda()
        }
        needsDisplay = true
    }

    // MARK: - Datos

    private var agendaURL: URL {
        URL(fileURLWithPath: "/Users/Shared/FractalAgenda/agenda.json")
    }

    private func loadAgenda() {
        lastLoad = Date()
        guard let data = try? Data(contentsOf: agendaURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            statusMessage = "Ejecuta FractalAgenda.app para cargar los eventos"
            work = []
            personal = []
            return
        }
        if let error = json["error"] as? String {
            statusMessage = error == "no_access"
                ? "FractalAgenda no tiene acceso a Calendario"
                : "Error al leer Calendario"
            work = []
            personal = []
            return
        }
        statusMessage = nil
        work = parse(json["work"])
        personal = parse(json["personal"])
    }

    private func parse(_ value: Any?) -> [AgendaItem] {
        guard let list = value as? [[String: Any]] else { return [] }
        return list.map { item in
            AgendaItem(
                time: item["time"] as? String ?? "",
                title: item["title"] as? String ?? "(sin título)",
                allDay: item["allDay"] as? Bool ?? false,
                end: (item["end"] as? String).flatMap { isoFormatter.date(from: $0) }
            )
        }
    }

    /// Eventos que aún no han terminado (los de todo el día siempre se muestran).
    private func upcoming(_ items: [AgendaItem], now: Date) -> [AgendaItem] {
        items.filter { $0.allDay || ($0.end ?? .distantFuture) > now }
    }

    // MARK: - Dibujo

    override func draw(_ rect: NSRect) {
        NSColor.black.setFill()
        bounds.fill()

        let w = bounds.width
        let h = bounds.height

        if let message = statusMessage {
            drawCentered(message,
                         font: NSFont.systemFont(ofSize: h * 0.028, weight: .regular),
                         color: .white, centerX: w / 2, centerY: h * 0.5)
            return
        }

        // Separador vertical entre columnas.
        NSColor.white.withAlphaComponent(0.2).setFill()
        NSRect(x: w / 2 - 0.5, y: h * 0.06, width: 1, height: h * 0.66).fill()

        let now = Date()
        let columnWidth = w * 0.40
        drawColumn(title: "Trabajo", items: upcoming(work, now: now), color: workColor,
                   left: w * 0.05, width: columnWidth, top: h * 0.705, height: h)
        drawColumn(title: "Personal", items: upcoming(personal, now: now), color: personalColor,
                   left: w * 0.55, width: columnWidth, top: h * 0.705, height: h)
    }

    /// Una sola columna alineada a la izquierda. Si no caben todos los eventos,
    /// se muestran los primeros.
    private func drawColumn(title: String, items: [AgendaItem], color: NSColor,
                            left: CGFloat, width: CGFloat, top: CGFloat, height h: CGFloat) {
        drawLeft(title, font: NSFont.systemFont(ofSize: h * 0.04, weight: .bold),
                 color: color, x: left, centerY: top)

        let rowHeight = h * 0.07
        let firstRowY = top - h * 0.085
        let bottomLimit = h * 0.06
        let rowsFit = max(1, Int((firstRowY - bottomLimit) / rowHeight) + 1)

        if items.isEmpty {
            drawLeft("No quedan eventos hoy", font: NSFont.systemFont(ofSize: h * 0.028, weight: .regular),
                     color: color.withAlphaComponent(0.6), x: left, centerY: firstRowY)
            return
        }

        let font = NSFont.systemFont(ofSize: h * 0.03, weight: .regular)
        for (row, item) in items.prefix(rowsFit).enumerated() {
            let y = firstRowY - CGFloat(row) * rowHeight
            drawEntry(item, font: font, color: color, x: left, width: width, centerY: y, height: h)
        }
    }

    /// Barra vertical del color del calendario, seguida de la hora y el título.
    private func drawEntry(_ item: AgendaItem, font: NSFont, color: NSColor,
                           x: CGFloat, width: CGFloat, centerY y: CGFloat, height h: CGFloat) {
        let barWidth = max(3, h * 0.005)
        let barHeight = h * 0.045
        color.setFill()
        NSRect(x: x, y: y - barHeight / 2, width: barWidth, height: barHeight).fill()

        let textX = x + barWidth + h * 0.015
        let text = item.time.isEmpty ? item.title : "\(item.time)  \(item.title)"
        let fitted = fit(text, font: font, maxWidth: width - barWidth - h * 0.015)
        drawLeft(fitted, font: font, color: .white, x: textX, centerY: y)
    }

    /// Recorta el texto con "…" hasta que quepa en maxWidth.
    private func fit(_ text: String, font: NSFont, maxWidth: CGFloat) -> String {
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        if NSAttributedString(string: text, attributes: attributes).size().width <= maxWidth {
            return text
        }
        var result = text
        while !result.isEmpty {
            result.removeLast()
            let candidate = result + "…"
            if NSAttributedString(string: candidate, attributes: attributes).size().width <= maxWidth {
                return candidate
            }
        }
        return "…"
    }

    private func drawLeft(_ text: String, font: NSFont, color: NSColor,
                          x: CGFloat, centerY: CGFloat) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        let string = NSAttributedString(string: text, attributes: attributes)
        let size = string.size()
        string.draw(at: NSPoint(x: x, y: centerY - size.height / 2))
    }

    @discardableResult
    private func drawCentered(_ text: String, font: NSFont, color: NSColor,
                              centerX: CGFloat, centerY: CGFloat) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        let string = NSAttributedString(string: text, attributes: attributes)
        let size = string.size()
        string.draw(at: NSPoint(x: centerX - size.width / 2, y: centerY - size.height / 2))
        return size.height
    }
}
