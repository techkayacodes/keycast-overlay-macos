import XCTest
@testable import KeycastOverlayCore

final class KeyMapTests: XCTestCase {
    func testKeyCodeLabels() {
        XCTAssertEqual(MacKeyMap.label(for: 8), "C")
        XCTAssertEqual(MacKeyMap.label(for: 36), "Enter")
        XCTAssertEqual(MacKeyMap.label(for: 49), "Space")
        XCTAssertEqual(MacKeyMap.label(for: 51), "⌫")
        XCTAssertEqual(MacKeyMap.label(for: 55), "⌘")
        XCTAssertEqual(MacKeyMap.label(for: 126), "↑")
        XCTAssertEqual(MacKeyMap.label(for: 122), "F1")
    }

    func testComboEmitsCanonicalOrderAndSuppressesLoneModifierOnRelease() {
        let tracker = KeyStateTracker(maxKeys: 8, highlight: 3)
        XCTAssertNil(tracker.handleFlagsChanged(active: [.shift]))
        XCTAssertNil(tracker.handleFlagsChanged(active: [.shift, .command]))
        XCTAssertEqual(tracker.handleKeyDown(keyCode: 17), "⌘+⇧+T")
        XCTAssertNil(tracker.handleFlagsChanged(active: [.command]))
        XCTAssertNil(tracker.handleFlagsChanged(active: []))
        XCTAssertEqual(tracker.keys, ["⌘+⇧+T"])
    }

    func testLoneCommandTapEmitsOnRelease() {
        let tracker = KeyStateTracker()
        XCTAssertNil(tracker.handleFlagsChanged(active: [.command]))
        XCTAssertEqual(tracker.handleFlagsChanged(active: []), "⌘")
        XCTAssertEqual(tracker.keys, ["⌘"])
    }

    func testRollingWindowAndGoldHighlightCutoff() {
        let tracker = KeyStateTracker(maxKeys: 4, highlight: 3)
        for key in ["A", "B", "C", "D", "E"] {
            tracker.push(key)
        }
        XCTAssertEqual(tracker.keys, ["B", "C", "D", "E"])
        XCTAssertEqual(
            tracker.chips(),
            [
                Chip(text: "B", recent: false),
                Chip(text: "C", recent: true),
                Chip(text: "D", recent: true),
                Chip(text: "E", recent: true),
            ]
        )
    }

    func testConfigParsingAndValidation() throws {
        let cfg = try OverlayConfig.parse(
            arguments: ["--max-keys", "10", "--highlight", "3", "--corner", "bottom-left", "--demo"],
            environment: [:]
        )
        XCTAssertEqual(cfg.maxKeys, 10)
        XCTAssertEqual(cfg.highlight, 3)
        XCTAssertEqual(cfg.corner, .bottomLeft)
        XCTAssertTrue(cfg.demo)

        XCTAssertThrowsError(try OverlayConfig(maxKeys: 0))
        XCTAssertThrowsError(try OverlayConfig(opacity: 0.1))
    }
}
