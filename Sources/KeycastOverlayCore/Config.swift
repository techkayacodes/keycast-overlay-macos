import Foundation

public enum OverlayCorner: String, CaseIterable, Sendable {
    case topRight = "top-right"
    case topLeft = "top-left"
    case bottomRight = "bottom-right"
    case bottomLeft = "bottom-left"
}

public struct OverlayConfig: Equatable, Sendable {
    public var maxKeys: Int
    public var highlight: Int
    public var fontSize: CGFloat
    public var marginTop: CGFloat
    public var marginRight: CGFloat
    public var corner: OverlayCorner
    public var clearAfter: TimeInterval
    public var opacity: CGFloat
    public var demo: Bool

    public init(
        maxKeys: Int = 8,
        highlight: Int = 3,
        fontSize: CGFloat = 12,
        marginTop: CGFloat = 44,
        marginRight: CGFloat = 16,
        corner: OverlayCorner = .topRight,
        clearAfter: TimeInterval = 0,
        opacity: CGFloat = 0.90,
        demo: Bool = false
    ) throws {
        guard maxKeys >= 1 else {
            throw ConfigError.invalidValue("max-keys must be >= 1")
        }
        guard highlight >= 0 else {
            throw ConfigError.invalidValue("highlight must be >= 0")
        }
        guard fontSize >= 6 else {
            throw ConfigError.invalidValue("font-size must be >= 6")
        }
        guard clearAfter >= 0 else {
            throw ConfigError.invalidValue("clear-after must be >= 0")
        }
        guard opacity >= 0.2 && opacity <= 1.0 else {
            throw ConfigError.invalidValue("opacity must be between 0.2 and 1.0")
        }
        self.maxKeys = maxKeys
        self.highlight = highlight
        self.fontSize = fontSize
        self.marginTop = marginTop
        self.marginRight = marginRight
        self.corner = corner
        self.clearAfter = clearAfter
        self.opacity = opacity
        self.demo = demo
    }

    public static func parse(
        arguments: [String],
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) throws -> OverlayConfig {
        var maxKeys = Int(environment["KEYCAST_MAX_KEYS"] ?? "") ?? 8
        var highlight = Int(environment["KEYCAST_HIGHLIGHT"] ?? "") ?? 3
        var fontSize = Double(environment["KEYCAST_FONT_SIZE"] ?? "") ?? 12.0
        var marginTop = Double(environment["KEYCAST_MARGIN_TOP"] ?? "") ?? 44.0
        var marginRight = Double(environment["KEYCAST_MARGIN_RIGHT"] ?? "") ?? 16.0
        var corner = OverlayCorner(rawValue: environment["KEYCAST_CORNER"] ?? "") ?? .topRight
        var clearAfter = Double(environment["KEYCAST_CLEAR_AFTER"] ?? "") ?? 0.0
        var opacity = Double(environment["KEYCAST_OPACITY"] ?? "") ?? 0.90
        var demo = ["1", "true", "yes", "on"].contains(
            (environment["KEYCAST_DEMO"] ?? "").trimmingCharacters(in: .whitespaces).lowercased()
        )

        var idx = 0
        while idx < arguments.count {
            let arg = arguments[idx]
            func nextValue(_ flag: String) throws -> String {
                idx += 1
                guard idx < arguments.count else {
                    throw ConfigError.invalidValue("missing value for \(flag)")
                }
                return arguments[idx]
            }

            switch arg {
            case "--max-keys":
                guard let v = Int(try nextValue(arg)) else {
                    throw ConfigError.invalidValue("invalid integer for --max-keys")
                }
                maxKeys = v
            case "--highlight":
                guard let v = Int(try nextValue(arg)) else {
                    throw ConfigError.invalidValue("invalid integer for --highlight")
                }
                highlight = v
            case "--font-size":
                guard let v = Double(try nextValue(arg)) else {
                    throw ConfigError.invalidValue("invalid number for --font-size")
                }
                fontSize = v
            case "--margin-top":
                guard let v = Double(try nextValue(arg)) else {
                    throw ConfigError.invalidValue("invalid number for --margin-top")
                }
                marginTop = v
            case "--margin-right":
                guard let v = Double(try nextValue(arg)) else {
                    throw ConfigError.invalidValue("invalid number for --margin-right")
                }
                marginRight = v
            case "--corner":
                let raw = try nextValue(arg)
                guard let c = OverlayCorner(rawValue: raw) else {
                    throw ConfigError.invalidValue("corner must be top-right, top-left, bottom-right, or bottom-left")
                }
                corner = c
            case "--clear-after":
                guard let v = Double(try nextValue(arg)) else {
                    throw ConfigError.invalidValue("invalid number for --clear-after")
                }
                clearAfter = v
            case "--opacity":
                guard let v = Double(try nextValue(arg)) else {
                    throw ConfigError.invalidValue("invalid number for --opacity")
                }
                opacity = v
            case "--demo":
                demo = true
            case "-h", "--help":
                throw ConfigError.helpRequested
            default:
                // Ignore macOS LaunchServices process serial number flag (-psn_*)
                if arg.hasPrefix("-psn_") {
                    break
                }
                throw ConfigError.invalidValue("unknown option: \(arg)")
            }
            idx += 1
        }

        return try OverlayConfig(
            maxKeys: maxKeys,
            highlight: highlight,
            fontSize: CGFloat(fontSize),
            marginTop: CGFloat(marginTop),
            marginRight: CGFloat(marginRight),
            corner: corner,
            clearAfter: clearAfter,
            opacity: CGFloat(opacity),
            demo: demo
        )
    }

    public static let usageText = """
    Usage: keycast-overlay [options]

    Options:
      --max-keys N        Maximum key chips kept on screen (default: 8)
      --highlight N       Newest keys highlighted in gold #d4af37 (default: 3)
      --font-size N       Key label font size in pt (default: 12)
      --corner CORNER     top-right | top-left | bottom-right | bottom-left (default: top-right)
      --margin-top N      Vertical margin from screen edge in px (default: 44)
      --margin-right N    Horizontal margin from screen edge in px (default: 16)
      --clear-after SEC   Seconds idle before clearing; 0 = never (default: 0)
      --opacity VAL       Overlay opacity 0.2..1.0 (default: 0.90)
      --demo              Preview static sample keys without Accessibility capture
      -h, --help          Show this help text
    """
}

public enum ConfigError: Error, LocalizedError, Equatable {
    case invalidValue(String)
    case helpRequested

    public var errorDescription: String? {
        switch self {
        case .invalidValue(let message): return message
        case .helpRequested: return OverlayConfig.usageText
        }
    }
}
