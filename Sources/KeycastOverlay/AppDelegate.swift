import AppKit
import KeycastOverlayCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private static let demoKeys = ["H", "E", "L", "⌘+C", "⌘+Enter", "Space", "⌫", "⌘"]
    private static let pauseCombo = "⌃+⌥+⇧+P"
    private static let quitCombo = "⌃+⌥+⇧+Q"

    private let config: OverlayConfig
    private let tracker: KeyStateTracker
    private var overlay: OverlayWindow?
    private var eventTap: GlobalEventTap?
    private var statusItem: NSStatusItem?
    private var pauseMenuItem: NSMenuItem?
    private var clearTimer: Timer?
    private var paused: Bool = false

    init(config: OverlayConfig) {
        self.config = config
        self.tracker = KeyStateTracker(maxKeys: config.maxKeys, highlight: config.highlight)
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if !config.demo && isAnotherInstanceRunning() {
            NSApp.terminate(nil)
            return
        }

        setupStatusBar()
        let win = OverlayWindow(config: config)
        overlay = win

        if config.demo {
            for k in Self.demoKeys {
                tracker.push(k)
            }
            win.render(chips: tracker.chips(), paused: false)
            return
        }

        if !GlobalEventTap.checkAccessibilityPermission(prompt: true) {
            showAccessibilityNotice()
        }

        let tap = GlobalEventTap { [weak self] event in
            DispatchQueue.main.async {
                self?.handle(event)
            }
        }
        if tap.start() {
            eventTap = tap
        } else {
            showAccessibilityNotice()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        clearTimer?.invalidate()
        eventTap?.stop()
    }

    private func handle(_ event: KeyEvent) {
        let emitted: String?
        switch event {
        case .flagsChanged(let mods):
            emitted = tracker.handleFlagsChanged(active: mods)
        case .keyDown(let keyCode, let mods):
            emitted = tracker.handleKeyDown(keyCode: keyCode, activeModifiers: mods)
        }

        guard let chipText = emitted else { return }

        if chipText == Self.quitCombo {
            NSApp.terminate(nil)
            return
        }
        if chipText == Self.pauseCombo {
            togglePause()
            return
        }
        guard !paused else { return }

        overlay?.render(chips: tracker.chips(), paused: false)
        scheduleClearTimer()
    }

    private func scheduleClearTimer() {
        clearTimer?.invalidate()
        clearTimer = nil
        guard config.clearAfter > 0 else { return }
        clearTimer = Timer.scheduledTimer(withTimeInterval: config.clearAfter, repeats: false) { [weak self] _ in
            self?.clearKeys()
        }
    }

    private func setupStatusBar() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "⌨"
        item.button?.toolTip = "keycast-overlay — Click for menu"

        let menu = NSMenu()
        let pauseItem = NSMenuItem(
            title: "Pause Overlay  (⌃⌥⇧P)",
            action: #selector(togglePause),
            keyEquivalent: ""
        )
        pauseItem.target = self
        pauseMenuItem = pauseItem
        menu.addItem(pauseItem)

        let clearItem = NSMenuItem(
            title: "Clear Keys",
            action: #selector(clearKeys),
            keyEquivalent: ""
        )
        clearItem.target = self
        menu.addItem(clearItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit keycast-overlay  (⌃⌥⇧Q)",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        item.menu = menu
        statusItem = item
    }

    @objc private func togglePause() {
        paused.toggle()
        tracker.clear()
        pauseMenuItem?.title = paused ? "Resume Overlay  (⌃⌥⇧P)" : "Pause Overlay  (⌃⌥⇧P)"
        overlay?.render(chips: tracker.chips(), paused: paused)
    }

    @objc private func clearKeys() {
        clearTimer?.invalidate()
        clearTimer = nil
        tracker.clear()
        overlay?.render(chips: tracker.chips(), paused: paused)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    private func isAnotherInstanceRunning() -> Bool {
        guard let bundleId = Bundle.main.bundleIdentifier else { return false }
        let currentPid = ProcessInfo.processInfo.processIdentifier
        return NSRunningApplication.runningApplications(withBundleIdentifier: bundleId)
            .contains { $0.processIdentifier != currentPid }
    }

    private func showAccessibilityNotice() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Needed"
        alert.informativeText = """
        macOS requires Accessibility permission to display global keystrokes.

        Open System Settings → Privacy & Security → Accessibility, enable KeycastOverlay (or your terminal), then relaunch keycast-overlay.

        Tip: You can preview the overlay without permission using --demo.
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
