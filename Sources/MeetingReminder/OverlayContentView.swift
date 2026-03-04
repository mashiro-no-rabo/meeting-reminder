import AppKit

final class OverlayContentView: NSView {
    private let onDismiss: () -> Void
    private let meetingURL: URL?
    private var keyPressCount = 0
    private var hintLabel: NSTextField!
    private var keyMonitor: Any?

    init(title: String, startDate: Date, location: String?, url: URL? = nil, notes: String? = nil, onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
        self.meetingURL = url ?? Self.extractMeetingURL(from: notes, location: location)
        super.init(frame: .zero)

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        // Title
        let titleLabel = makeLabel(title, font: .boldSystemFont(ofSize: 64), color: .white)

        // Time
        let secondsUntil = Int(startDate.timeIntervalSinceNow)
        let timeText: String
        if secondsUntil > 0 {
            timeText = "Starts at \(timeFormatter.string(from: startDate)) (in \(Self.formatDuration(secondsUntil)))"
        } else {
            timeText = "Starts at \(timeFormatter.string(from: startDate))"
        }
        let timeLabel = makeLabel(
            timeText,
            font: .systemFont(ofSize: 32),
            color: .white
        )

        // Stack: title, time, optional location, buttons, hint
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(timeLabel)

        // Location
        if let location, !location.isEmpty {
            let locLabel = makeLabel(location, font: .systemFont(ofSize: 28), color: .white.withAlphaComponent(0.8))
            stack.addArrangedSubview(locLabel)
        }

        // Button row
        let buttonRow = NSStackView()
        buttonRow.orientation = .horizontal
        buttonRow.spacing = 20

        // Open Meeting Link button (only if URL exists)
        if let meetingURL {
            let urlLabel = makeLabel(meetingURL.absoluteString, font: .systemFont(ofSize: 18), color: .white.withAlphaComponent(0.6))
            stack.addArrangedSubview(urlLabel)

            let openButton = NSButton(title: "Join", target: self, action: #selector(openMeetingLink))
            styleButton(openButton, width: 240)
            openButton.layer?.backgroundColor = NSColor.systemBlue.withAlphaComponent(0.4).cgColor
            buttonRow.addArrangedSubview(openButton)
        }

        // Dismiss button
        let dismissButton = NSButton(title: "Dismiss", target: self, action: #selector(dismissClicked))
        styleButton(dismissButton, width: 240)
        buttonRow.addArrangedSubview(dismissButton)

        stack.setCustomSpacing(40, after: stack.arrangedSubviews.last!)
        stack.addArrangedSubview(buttonRow)

        // Hint
        let hint = NSTextField(labelWithString: "Press ESC or Enter twice to dismiss")
        hint.font = NSFont.systemFont(ofSize: 18)
        hint.textColor = NSColor.white.withAlphaComponent(0.5)
        stack.addArrangedSubview(hint)
        hintLabel = hint

        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }

    private static func formatDuration(_ totalSeconds: Int) -> String {
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        } else if minutes > 0 {
            return seconds > 0 ? "\(minutes)m \(seconds)s" : "\(minutes)m"
        } else {
            return "\(seconds)s"
        }
    }

    private static func extractMeetingURL(from notes: String?, location: String?) -> URL? {
        let meetingPatterns = [
            "https://[a-zA-Z0-9.-]*zoom\\.us/[^\\s<>\"]+",
            "https://teams\\.microsoft\\.com/[^\\s<>\"]+",
            "https://meet\\.google\\.com/[^\\s<>\"]+",
            "https://[a-zA-Z0-9.-]*webex\\.com/[^\\s<>\"]+",
            "https://[a-zA-Z0-9.-]*chime\\.aws/[^\\s<>\"]+",
        ]
        let pattern = meetingPatterns.joined(separator: "|")
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }

        for text in [location, notes].compactMap({ $0 }) {
            let range = NSRange(text.startIndex..., in: text)
            if let match = regex.firstMatch(in: text, range: range),
               let matchRange = Range(match.range, in: text) {
                return URL(string: String(text[matchRange]))
            }
        }
        return nil
    }

    private func makeLabel(_ text: String, font: NSFont, color: NSColor) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = font
        label.textColor = color
        label.alignment = .center
        return label
    }

    private func styleButton(_ button: NSButton, width: CGFloat) {
        button.bezelStyle = .rounded
        button.font = NSFont.boldSystemFont(ofSize: 36)
        button.contentTintColor = .white
        button.isBordered = false
        button.wantsLayer = true
        button.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.2).cgColor
        button.layer?.cornerRadius = 12
        button.layer?.borderWidth = 2
        button.layer?.borderColor = NSColor.white.withAlphaComponent(0.6).cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: width).isActive = true
        button.heightAnchor.constraint(equalToConstant: 64).isActive = true
    }

    @objc private func openMeetingLink() {
        if let url = meetingURL {
            NSWorkspace.shared.open(url)
        }
        onDismiss()
    }

    @objc private func dismissClicked() {
        onDismiss()
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.withAlphaComponent(0.75).setFill()
        dirtyRect.fill()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self else { return event }
                if event.keyCode == 53 || event.keyCode == 36 || event.keyCode == 76 {
                    // 53 = ESC, 36 = Return, 76 = Numpad Enter
                    self.keyPressCount += 1
                    if self.keyPressCount >= 2 {
                        self.onDismiss()
                    } else {
                        self.hintLabel.stringValue = "Press again to dismiss"
                    }
                    return nil
                }
                return event
            }
        } else {
            removeKeyMonitor()
        }
    }

    func removeKeyMonitor() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
    }
}
