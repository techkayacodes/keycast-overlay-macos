import ApplicationServices
import Foundation
import KeycastOverlayCore

enum KeyEvent {
    case keyDown(keyCode: UInt16, modifiers: Set<ModifierKey>)
    case flagsChanged(modifiers: Set<ModifierKey>)
}

/// Global macOS keyboard listener powered by `CGEvent.tapCreate`.
final class GlobalEventTap {
    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private let handler: (KeyEvent) -> Void

    init(handler: @escaping (KeyEvent) -> Void) {
        self.handler = handler
    }

    static func checkAccessibilityPermission(prompt: Bool) -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    func start() -> Bool {
        let mask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.flagsChanged.rawValue)
        let refcon = Unmanaged.passUnretained(self).toOpaque()

        guard let created = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(mask),
            callback: { _, type, event, userInfo in
                guard let userInfo else { return Unmanaged.passUnretained(event) }
                let listener = Unmanaged<GlobalEventTap>.fromOpaque(userInfo).takeUnretainedValue()

                if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                    if let tap = listener.tap {
                        CGEvent.tapEnable(tap: tap, enable: true)
                    }
                    return Unmanaged.passUnretained(event)
                }

                let mods = GlobalEventTap.extractModifiers(event.flags)
                if type == .keyDown {
                    let code = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
                    listener.handler(.keyDown(keyCode: code, modifiers: mods))
                } else if type == .flagsChanged {
                    listener.handler(.flagsChanged(modifiers: mods))
                }
                return Unmanaged.passUnretained(event)
            },
            userInfo: refcon
        ) else {
            return false
        }

        tap = created
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, created, 0)
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: created, enable: true)
        return true
    }

    func stop() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            runLoopSource = nil
        }
        if let tap {
            CGEvent.tapEnable(tap: tap, enable: false)
            self.tap = nil
        }
    }

    private static func extractModifiers(_ flags: CGEventFlags) -> Set<ModifierKey> {
        var result = Set<ModifierKey>()
        if flags.contains(.maskCommand) { result.insert(.command) }
        if flags.contains(.maskControl) { result.insert(.control) }
        if flags.contains(.maskAlternate) { result.insert(.option) }
        if flags.contains(.maskShift) { result.insert(.shift) }
        return result
    }
}
