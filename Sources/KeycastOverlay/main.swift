import AppKit
import Foundation
import KeycastOverlayCore

let args = Array(CommandLine.arguments.dropFirst())
let config: OverlayConfig
do {
    config = try OverlayConfig.parse(arguments: args)
} catch ConfigError.helpRequested {
    print(OverlayConfig.usageText)
    exit(0)
} catch {
    fputs("error: \(error.localizedDescription)\n", stderr)
    exit(2)
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate(config: config)
app.delegate = delegate
app.run()
