# keycast-overlay-macos

A lightweight, native **macOS 13+** keystroke overlay built in Swift & AppKit that displays your most recent key presses in a translucent, click-through strip on screen.

Created by **Kemal Codes ([@techkayacodes](https://github.com/techkayacodes))** as the macOS edition of the `keycast-overlay` family, inspired by the Linux keystroke visualizer [Show Me The Key](https://github.com/AlynxZhou/showmethekey).

Built with **zero third-party dependencies** using native Swift, AppKit, and `CGEventTap`, designed for screen recordings, coding tutorials, live streams, and pair programming.

## Cross-Platform Editions

| Platform | Repository | Implementation |
|---|---|---|
| **Windows 10 / 11** *(Featured — includes clickable `.exe`)* | [techkayacodes/keycast-overlay-windows](https://github.com/techkayacodes/keycast-overlay-windows) | Native Win32 `WH_KEYBOARD_LL` + click-through overlay + system tray |
| **macOS 13+** *(this repo)* | [techkayacodes/keycast-overlay-macos](https://github.com/techkayacodes/keycast-overlay-macos) | Native Swift / AppKit `NSPanel` + `CGEventTap` + menu bar app |
| **Linux (Wayland)** *(Original)* | [techkayacodes/keycast-overlay](https://github.com/techkayacodes/keycast-overlay) | GTK 4 + `gtk4-layer-shell` + `showmethekey-cli` |

## Design & Signature Features

Designed by **[@techkayacodes](https://github.com/techkayacodes)** for clean visibility without getting in the way:

- **Gold recency highlight (`#d4af37`)**: the **3 most recent keystrokes** stand out with a crisp gold outline, subtle gold halo, and bold bright-white text.
- **Dimmed keystroke history**: older keys fade into a muted grey style (up to 8 visible chips), keeping context visible without visual clutter.
- **Clean placement & compact sizing**: anchored by default in the upper-right below the menu bar and window headers (`margin-top: 44px`, `margin-right: 16px`), sized for clean readability across Retina and external displays.
- **Native macOS symbols & combos**: displays chords as one chip (`⌘+C`, `⌘+⇧+T`, `⌘+Enter`) and captures lone modifier taps (like tapping `⌘`).
- **Truly click-through & Space-aware**: uses a non-activating borderless `NSPanel` (`ignoresMouseEvents = true`, `level = .statusBar`, `canJoinAllSpaces`, `fullScreenAuxiliary`) so it floats over full-screen apps, never takes focus, and never blocks clicks.
- **Menu bar controls & privacy hotkeys**: click the `⌨` menu bar icon to **Pause / Resume**, **Clear Keys**, or **Quit** — or press `⌃⌥⇧P` to pause/hide and `⌃⌥⇧Q` to quit.
- **Zero disk logging**: key labels live strictly in memory while displayed on screen.

## Build & Install (macOS 13+)

Requires Xcode Command Line Tools (`xcode-select --install`).

### Build & Install Clickable `KeycastOverlay.app`

```bash
git clone https://github.com/techkayacodes/keycast-overlay-macos.git
cd keycast-overlay-macos
./install.sh
```

This builds `dist/KeycastOverlay.app` and installs it to `/Applications/KeycastOverlay.app` so you can double-click it or launch it from Spotlight.

### Or Run from Terminal

```bash
swift run keycast-overlay --demo   # preview static sample keys (no permissions needed)
swift run keycast-overlay          # start live overlay
```

### Accessibility Permission

macOS requires Accessibility permission for global keyboard listeners:
1. Open **System Settings → Privacy & Security → Accessibility**.
2. Enable **KeycastOverlay** (or your terminal if running via `swift run`).
3. Relaunch `KeycastOverlay`.

## Configuration Options

| CLI Flag         | Environment Variable   | Default     | Description                                            |
|------------------|------------------------|-------------|--------------------------------------------------------|
| `--max-keys`     | `KEYCAST_MAX_KEYS`     | `8`         | Maximum number of key chips kept on screen             |
| `--highlight`    | `KEYCAST_HIGHLIGHT`    | `3`         | Number of newest keys highlighted in gold (`#d4af37`)  |
| `--font-size`    | `KEYCAST_FONT_SIZE`    | `12`        | Key label font size in points                          |
| `--corner`       | `KEYCAST_CORNER`       | `top-right` | `top-right`, `top-left`, `bottom-right`, `bottom-left` |
| `--margin-top`   | `KEYCAST_MARGIN_TOP`   | `44`        | Vertical margin from the visible screen edge (px)      |
| `--margin-right` | `KEYCAST_MARGIN_RIGHT` | `16`        | Horizontal margin from the visible screen edge (px)    |
| `--clear-after`  | `KEYCAST_CLEAR_AFTER`  | `0`         | Seconds idle before clearing (`0` = never clear)       |
| `--opacity`      | `KEYCAST_OPACITY`      | `0.90`      | Overlay opacity (`0.2` to `1.0`)                       |
| `--demo`         | `KEYCAST_DEMO`         | `0`         | Preview static sample chips without Accessibility tap  |

## Running Tests

```bash
swift test
```

## Privacy

Like any on-screen keystroke visualizer, this app listens to global keyboard events while running. It **only** displays key labels on screen — it never writes keys to disk and never sends data over the network. Press `⌃⌥⇧P` or use the menu bar icon to pause before typing passwords on a recorded or shared screen.

## Credits & Attribution

- **Original Inspiration — [Show Me The Key](https://github.com/AlynxZhou/showmethekey)** by [AlynxZhou](https://github.com/AlynxZhou): the Linux keystroke visualizer that inspired the concept of a clean, real-time on-screen key display.
- **macOS Edition & Visual Design — [@techkayacodes](https://github.com/techkayacodes) (Kemal Codes)**: native Swift/AppKit implementation, default screen placement and compact chip sizing, gold highlight (`#d4af37`) on the 3 most recent keystrokes, and dimmed greyed-out styling for older keys (shared across the Windows and Wayland editions).

## License

MIT. See [LICENSE](LICENSE).
