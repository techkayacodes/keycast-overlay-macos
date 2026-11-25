import Foundation

public struct Chip: Equatable, Sendable {
    public let text: String
    public let recent: Bool

    public init(text: String, recent: Bool) {
        self.text = text
        self.recent = recent
    }
}

public enum ModifierKey: String, CaseIterable, Hashable, Sendable {
    case command = "⌘"
    case control = "⌃"
    case option = "⌥"
    case shift = "⇧"

    public static let canonicalOrder: [ModifierKey] = [.command, .control, .option, .shift]
}

/// Maps macOS virtual key codes (HIToolbox / CGKeyCode) to compact chip labels.
public enum MacKeyMap {
    public static let modifierKeyCodes: [UInt16: ModifierKey] = [
        55: .command, // kVK_Command (Left)
        54: .command, // kVK_RightCommand
        59: .control, // kVK_Control (Left)
        62: .control, // kVK_RightControl
        58: .option,  // kVK_Option (Left)
        61: .option,  // kVK_RightOption
        56: .shift,   // kVK_Shift (Left)
        60: .shift,   // kVK_RightShift
    ]

    public static let keyNames: [UInt16: String] = [
        // Letters (US ANSI layout keycodes)
        0: "A", 11: "B", 8: "C", 2: "D", 14: "E", 3: "F", 5: "G", 4: "H",
        34: "I", 38: "J", 40: "K", 37: "L", 46: "M", 45: "N", 31: "O", 35: "P",
        12: "Q", 15: "R", 1: "S", 17: "T", 32: "U", 9: "V", 13: "W", 7: "X",
        16: "Y", 6: "Z",
        // Top-row digits
        29: "0", 18: "1", 19: "2", 20: "3", 21: "4", 23: "5", 22: "6",
        26: "7", 28: "8", 25: "9",
        // Punctuation
        27: "-", 24: "=", 33: "[", 30: "]", 42: "\\", 41: ";", 39: "'",
        43: ",", 47: ".", 44: "/", 50: "`",
        // Control & editing
        36: "Enter", 76: "Enter", 48: "Tab", 49: "Space", 51: "⌫",
        117: "Del", 53: "Esc", 57: "Caps",
        // Navigation
        123: "←", 124: "→", 125: "↓", 126: "↑",
        115: "Home", 119: "End", 116: "PgUp", 121: "PgDn",
        // Function keys
        122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6",
        98: "F7", 100: "F8", 101: "F9", 109: "F10", 103: "F11", 111: "F12",
        105: "F13", 107: "F14", 113: "F15", 106: "F16", 64: "F17", 79: "F18",
        80: "F19", 90: "F20",
        // Numpad
        82: "0", 83: "1", 84: "2", 85: "3", 86: "4", 87: "5", 88: "6",
        89: "7", 91: "8", 92: "9", 65: ".", 67: "*", 69: "+", 75: "/", 78: "-", 81: "=",
    ]

    public static func label(for keyCode: UInt16) -> String? {
        if let mod = modifierKeyCodes[keyCode] {
            return mod.rawValue
        }
        return keyNames[keyCode]
    }
}

/// Tracks active modifiers and maintains the rolling list of recent keystroke chips.
public final class KeyStateTracker {
    public let maxKeys: Int
    public let highlight: Int
    public private(set) var keys: [String] = []

    private var activeModifiers: Set<ModifierKey> = []
    private var modUsedWithKey: Bool = false

    public init(maxKeys: Int = 8, highlight: Int = 3) {
        self.maxKeys = maxKeys
        self.highlight = highlight
    }

    /// Update active modifiers from a macOS `flagsChanged` event.
    /// Emits a lone modifier chip (e.g. `⌘`) when a single modifier is tapped and released.
    @discardableResult
    public func handleFlagsChanged(active: Set<ModifierKey>) -> String? {
        let added = active.subtracting(activeModifiers)
        let removed = activeModifiers.subtracting(active)

        if activeModifiers.isEmpty && !added.isEmpty {
            modUsedWithKey = false
        }

        let wasSingleModifier = activeModifiers.count == 1
        let loneModifier = activeModifiers.first

        activeModifiers = active

        if active.isEmpty && !removed.isEmpty && wasSingleModifier && !modUsedWithKey,
           let tapped = loneModifier
        {
            return push(tapped.rawValue)
        }
        return nil
    }

    /// Record a non-modifier keyDown event combined with currently held modifiers.
    @discardableResult
    public func handleKeyDown(keyCode: UInt16, activeModifiers overrideMods: Set<ModifierKey>? = nil) -> String? {
        if MacKeyMap.modifierKeyCodes[keyCode] != nil {
            return nil
        }
        guard let label = MacKeyMap.label(for: keyCode) else {
            return nil
        }
        let modsSet = overrideMods ?? activeModifiers
        let ordered = ModifierKey.canonicalOrder.filter { modsSet.contains($0) }.map(\.rawValue)
        if !ordered.isEmpty {
            modUsedWithKey = true
            return push((ordered + [label]).joined(separator: "+"))
        }
        return push(label)
    }

    @discardableResult
    public func push(_ text: String) -> String {
        keys.append(text)
        if keys.count > maxKeys {
            keys.removeFirst(keys.count - maxKeys)
        }
        return text
    }

    public func clear() {
        keys.removeAll()
    }

    public func chips() -> [Chip] {
        let cutoff = keys.count - highlight
        return keys.enumerated().map { idx, text in
            Chip(text: text, recent: idx >= cutoff)
        }
    }
}
