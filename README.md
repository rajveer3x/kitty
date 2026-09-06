# Kitty

Kitty is a small, local-only macOS menu-bar companion that shows a cute animated cat. The cat walks in place during normal use and switches to a more energetic run when aggregate system CPU usage stays above the configured threshold.

## Features

- Menu-bar-only app; no Dock window.
- Aggregate CPU usage sampled every 2 seconds during normal power use.
- Walking at 4 lightweight keyframes per second.
- Running at 8 lightweight keyframes per second after CPU stays above 70% for 3 seconds.
- Returns to walking after CPU stays at or below the threshold for 10 seconds.
- Pause control changes Kitty to a curled sleeping pose.
- Animation pauses during sleep and Low Power Mode.
- CPU sampling relaxes to every 10 seconds in Low Power Mode.
- Runtime CPU threshold slider, default 70%.
- Optional macOS Launch at Login toggle using `SMAppService`.
- Popover closes after 2 seconds without interaction.

## Privacy and safety

Kitty is fully local. It reads only aggregate Mach CPU counters and macOS sleep/power state. It does not inspect individual processes, files, microphone, camera, screen, keyboard input, Accessibility APIs, or network resources. It does not collect, upload, or persist usage data. The threshold and pause controls are runtime-only; macOS manages the optional Login Item registration.

The target uses App Sandbox and has no App Groups or network entitlement. No login item is enabled until the user turns on **Launch Kitty at login** in Kitty’s menu.

No software can use literally zero energy, but Kitty is intentionally conservative: the expensive work is a tiny vector status item, CPU sampling is infrequent, and animation is disabled or greatly reduced in sleep, pause, and Low Power Mode.

## Run from Xcode

1. Open `kitty.xcodeproj` in Xcode.
2. Select the `kitty` scheme and **My Mac**.
3. Press `⌘R`.
4. Look in the macOS menu bar; Kitty does not open a normal window.

## Install without Xcode

1. Choose **Product → Archive**.
2. In Organizer, choose **Distribute App → Direct Distribution**.
3. Export or copy `Kitty.app` into `/Applications`.
4. Open it once, then enable **Launch Kitty at login** if desired.

## Project structure

- `kitty/kittyApp.swift` — SwiftUI app lifecycle and agent-only Settings scene.
- `kitty/AppDelegate.swift` — reliable AppKit status-bar slot and SwiftUI popover.
- `kitty/CPUMonitor.swift` — local CPU sampling, gait thresholds, sleep/power handling.
- `kitty/CatStatusItem.swift` — chibi vector cat, smooth walk/run keyframes, and sleeping pose.
- `kitty/KittyMenu.swift` — CPU readout and controls.
- `kitty/LoginItemManager.swift` — user-controlled macOS Login Item registration.

## Verification

The source is type-checked with the project’s Swift concurrency settings. Full Xcode archive/signing requires Xcode and the local developer account.
