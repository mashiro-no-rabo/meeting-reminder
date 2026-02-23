import AppKit

final class OverlayContentView: NSView {
    private let title: String
    private let startDate: Date
    private let onDismiss: () -> Void

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    init(title: String, startDate: Date, onDismiss: @escaping () -> Void) {
        self.title = title
        self.startDate = startDate
        self.onDismiss = onDismiss
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }

    override func draw(_ dirtyRect: NSRect) {
        // Semi-transparent dark background
        NSColor.black.withAlphaComponent(0.75).setFill()
        dirtyRect.fill()

        let centerX = bounds.midX
        let centerY = bounds.midY

        // Meeting title
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 64),
            .foregroundColor: NSColor.white,
        ]
        let titleStr = title as NSString
        let titleSize = titleStr.size(withAttributes: titleAttrs)
        titleStr.draw(
            at: NSPoint(x: centerX - titleSize.width / 2, y: centerY - titleSize.height / 2 + 40),
            withAttributes: titleAttrs
        )

        // "Starts at HH:MM"
        let timeText = "Starts at \(Self.timeFormatter.string(from: startDate))" as NSString
        let timeAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 32),
            .foregroundColor: NSColor.white,
        ]
        let timeSize = timeText.size(withAttributes: timeAttrs)
        timeText.draw(
            at: NSPoint(x: centerX - timeSize.width / 2, y: centerY - titleSize.height / 2 - 30),
            withAttributes: timeAttrs
        )

        // Dismiss hint
        let hintText = "Click, ESC, or Enter to dismiss" as NSString
        let hintAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 18),
            .foregroundColor: NSColor.white.withAlphaComponent(0.5),
        ]
        let hintSize = hintText.size(withAttributes: hintAttrs)
        hintText.draw(
            at: NSPoint(x: centerX - hintSize.width / 2, y: centerY - titleSize.height / 2 - 90),
            withAttributes: hintAttrs
        )
    }

    override var acceptsFirstResponder: Bool { true }

    override func mouseDown(with event: NSEvent) {
        onDismiss()
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 || event.keyCode == 36 || event.keyCode == 76 {
            // 53 = ESC, 36 = Return, 76 = Numpad Enter
            onDismiss()
        }
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }
}
