# Kitty

Kitty is a tiny, local-only macOS menu-bar app with a cute animated cat. It stays in one place while its legs and tail move in place. The animation becomes a faster run only when the Mac is under sustained CPU load.

## Highlights

- Menu-bar-only: Kitty does not create a Dock icon or normal app window.
- Aggregate CPU usage is sampled every 2 seconds during normal power use.
- Walking uses a small 4 FPS frame set; running uses 8 FPS.
- Running starts after CPU stays above the configured threshold for 3 seconds.
- Walking resumes after CPU stays at or below the threshold for 10 seconds.
- Manual pause changes the cat to a still sleeping pose.
- Sleep and Low Power Mode pause or greatly reduce work.
- CPU threshold is adjustable, with a default of 70%.
- Popover closes automatically after 2 seconds without interaction.
- Optional **Launch Kitty at login** support.

## Privacy, safety, and battery use

Kitty works entirely on the Mac. It reads only aggregate Mach CPU counters and macOS sleep/power state. It does not use networking, inspect individual processes or files, access the microphone, camera, screen recording, Accessibility APIs, or collect any personal data.

The app uses App Sandbox and Hardened Runtime. It has no network entitlement and no App Groups. CPU sampling is intentionally infrequent, animation uses a tiny vector view, and work is paused or reduced during sleep, Low Power Mode, or manual pause. No app can use literally zero energy, but Kitty is designed to have a very small battery and CPU footprint.

## Run from Xcode

1. Open `kitty.xcodeproj` in Xcode.
2. Select the `kitty` scheme and **My Mac**.
3. Press **⌘R**.
4. Look at the macOS menu bar for the cat. Kitty does not open a normal window.

## Install and run without Xcode

For personal use, the simplest export is **Copy App**:

1. In Xcode choose **Product → Archive**.
2. In Organizer choose **Distribute App → Custom → Copy App**.
3. Choose a destination such as Desktop and click **Export**.
4. Open the exported folder and drag `Kitty.app` into `/Applications`.
5. Launch Kitty from Applications or Spotlight. Xcode can now be closed.

If Xcode asks for a signing team, select your Apple ID under the target's **Signing & Capabilities** tab and enable **Automatically manage signing**. Create a new archive after changing signing settings; do not reuse an older archive.

## What “Launch Kitty at login” means

When enabled, macOS starts Kitty automatically after you sign in. It does not keep Xcode open, create a separate background daemon, or send anything over the network. Kitty registers only the app itself through Apple's `SMAppService` Login Item API.

To use it safely:

1. Install `Kitty.app` in `/Applications` first.
2. Open the menu-bar cat and enable **Launch Kitty at login**.
3. macOS may show Kitty under **System Settings → General → Login Items**.

Turn the toggle off in Kitty, or remove Kitty from Login Items, to stop automatic launch. The setting is optional and is off by default.

## Menu controls

- Current CPU usage
- CPU threshold slider
- Pause/resume animation
- Launch Kitty at login
- Quit Kitty

## Project structure

- `kitty/kittyApp.swift` — SwiftUI app entry point and menu-bar scene.
- `kitty/AppDelegate.swift` — AppKit status item and popover lifecycle.
- `kitty/CPUMonitor.swift` — local CPU sampling, gait thresholds, and power-state handling.
- `kitty/CatStatusItem.swift` — vector cat, walking/running frames, tail motion, and sleeping pose.
- `kitty/KittyMenu.swift` — CPU readout and user controls.
- `kitty/LoginItemManager.swift` — optional macOS Login Item registration.
- `kitty/Assets.xcassets/AppIcon.appiconset` — Kitty application icon and retina variants.

## Verification

The Swift sources are type-checked with the project's concurrency settings. Full archive, signing, and export are performed by Xcode using the developer account configured on the Mac.
