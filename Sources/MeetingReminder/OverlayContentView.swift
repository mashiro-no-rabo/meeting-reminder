import AppKit

final class OverlayContentView: NSView {
    private let onDismiss: () -> Void
    private var keyPressCount = 0
    private var hintLabel: NSTextField!
    private var keyMonitor: Any?

    init(title: String, startDate: Date, location: String?, onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
        super.init(frame: .zero)

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        // Title
        let titleLabel = makeLabel(title, font: .boldSystemFont(ofSize: 64), color: .white)

        // Time
        let timeLabel = makeLabel(
            "Starts at \(timeFormatter.string(from: startDate))",
            font: .systemFont(ofSize: 32),
            color: .white
        )

        // Stack: title, time, optional location, button, hint
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

        // Dismiss button with explicit size for symmetric padding
        let button = NSButton(title: "Dismiss", target: self, action: #selector(dismissClicked))
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
        button.widthAnchor.constraint(equalToConstant: 240).isActive = true
        button.heightAnchor.constraint(equalToConstant: 64).isActive = true
        stack.setCustomSpacing(40, after: stack.arrangedSubviews.last!)
        stack.addArrangedSubview(button)

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

    private func makeLabel(_ text: String, font: NSFont, color: NSColor) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = font
        label.textColor = color
        label.alignment = .center
        return label
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
