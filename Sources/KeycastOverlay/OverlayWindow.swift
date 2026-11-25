import AppKit
import KeycastOverlayCore

/// Borderless, translucent, click-through floating panel drawing dark-and-gold keycap chips.
final class OverlayWindow: NSPanel {
    private let config: OverlayConfig
    private let stackView = NSStackView()

    private static let goldColor = NSColor(
        calibratedRed: 212.0 / 255.0,
        green: 175.0 / 255.0,
        blue: 55.0 / 255.0,
        alpha: 1.0
    )
    private static let recentBg = NSColor(calibratedWhite: 20.0 / 255.0, alpha: 0.78)
    private static let oldBg = NSColor(calibratedWhite: 24.0 / 255.0, alpha: 0.48)
    private static let oldBorder = NSColor(calibratedWhite: 1.0, alpha: 0.14)
    private static let oldFg = NSColor(calibratedWhite: 1.0, alpha: 0.48)

    init(config: OverlayConfig) {
        self.config = config
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 100, height: 36),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true
        level = .statusBar
        alphaValue = config.opacity
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        hidesOnDeactivate = false

        stackView.orientation = .horizontal
        stackView.alignment = .centerY
        stackView.spacing = 6
        stackView.edgeInsets = NSEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        let container = NSView()
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.clear.cgColor
        container.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: container.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        contentView = container
        orderOut(nil)
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func render(chips: [Chip], paused: Bool) {
        for view in stackView.arrangedSubviews {
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        guard !chips.isEmpty, !paused else {
            orderOut(nil)
            return
        }

        for chip in chips {
            stackView.addArrangedSubview(makeChipView(chip))
        }

        stackView.layoutSubtreeIfNeeded()
        let size = stackView.fittingSize
        position(size: size)
        orderFrontRegardless()
    }

    private func makeChipView(_ chip: Chip) -> NSView {
        let pill = NSView()
        pill.wantsLayer = true
        pill.translatesAutoresizingMaskIntoConstraints = false

        let layer = pill.layer!
        layer.cornerRadius = 6
        layer.masksToBounds = false
        layer.borderWidth = chip.recent ? 1.5 : 1.0
        layer.backgroundColor = (chip.recent ? Self.recentBg : Self.oldBg).cgColor
        layer.borderColor = (chip.recent ? Self.goldColor : Self.oldBorder).cgColor

        if chip.recent {
            layer.shadowColor = Self.goldColor.cgColor
            layer.shadowOpacity = 0.55
            layer.shadowRadius = 4
            layer.shadowOffset = .zero
        }

        let label = NSTextField(labelWithString: chip.text)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.alignment = .center
        label.font = NSFont.systemFont(
            ofSize: config.fontSize,
            weight: chip.recent ? .bold : .semibold
        )
        label.textColor = chip.recent ? .white : Self.oldFg

        pill.addSubview(label)
        let padX = max(8.0, config.fontSize * 0.65)
        let padY = max(4.0, config.fontSize * 0.30)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: pill.leadingAnchor, constant: padX),
            label.trailingAnchor.constraint(equalTo: pill.trailingAnchor, constant: -padX),
            label.topAnchor.constraint(equalTo: pill.topAnchor, constant: padY),
            label.bottomAnchor.constraint(equalTo: pill.bottomAnchor, constant: -padY),
        ])

        return pill
    }

    private func position(size: NSSize) {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let frame = screen.visibleFrame

        let x: CGFloat
        switch config.corner {
        case .topRight, .bottomRight:
            x = frame.maxX - size.width - config.marginRight
        case .topLeft, .bottomLeft:
            x = frame.minX + config.marginRight
        }

        let y: CGFloat
        switch config.corner {
        case .topRight, .topLeft:
            y = frame.maxY - size.height - config.marginTop
        case .bottomRight, .bottomLeft:
            y = frame.minY + config.marginTop
        }

        setFrame(NSRect(origin: NSPoint(x: x, y: y), size: size), display: true)
    }
}
