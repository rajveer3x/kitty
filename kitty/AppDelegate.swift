import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusController = KittyStatusController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusController.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        statusController.stop()
    }
}

/// AppKit owns the status-bar slot; its content and popover remain SwiftUI.
/// This avoids relying on menu-extra layout behavior for a custom animated view.
@MainActor
final class KittyStatusController: NSObject {
    private let cpuMonitor = CPUMonitor()
    private let loginItemManager = LoginItemManager()
    private let popover = NSPopover()
    private var statusItem: NSStatusItem?
    private var dismissTimer: Timer?
    private var activityMonitor: Any?

    func start() {
        guard statusItem == nil else { return }

        let item = NSStatusBar.system.statusItem(withLength: 36)
        guard let button = item.button else { return }
        button.imagePosition = .imageOnly
        button.setAccessibilityLabel("Kitty")
        button.target = self
        button.action = #selector(togglePopover)

        let catView = StatusButtonHostingView(rootView: CatStatusItem(cpuMonitor: cpuMonitor))
        catView.frame = button.bounds
        catView.autoresizingMask = [.width, .height]
        button.addSubview(catView)

        popover.behavior = .transient
        popover.delegate = self
        popover.contentViewController = NSHostingController(rootView: KittyMenu(cpuMonitor: cpuMonitor, loginItemManager: loginItemManager))
        popover.contentSize = NSSize(width: 230, height: 260)
        statusItem = item
    }

    func stop() {
        closePopover()
        if let statusItem { NSStatusBar.system.removeStatusItem(statusItem) }
        statusItem = nil
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button else { return }
        if popover.isShown {
            closePopover()
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            beginTrackingPopoverActivity()
        }
    }

    private func beginTrackingPopoverActivity() {
        resetDismissTimer()
        activityMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .mouseMoved, .scrollWheel, .keyDown]) { [weak self] event in
            MainActor.assumeIsolated { self?.resetDismissTimer() }
            return event
        }
    }

    private func resetDismissTimer() {
        dismissTimer?.invalidate()
        let timer = Timer(timeInterval: 2, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated { self?.closePopover() }
        }
        RunLoop.main.add(timer, forMode: .common)
        dismissTimer = timer
    }

    private func closePopover() {
        dismissTimer?.invalidate()
        dismissTimer = nil
        if let activityMonitor { NSEvent.removeMonitor(activityMonitor) }
        activityMonitor = nil
        if popover.isShown { popover.performClose(nil) }
    }
}

extension KittyStatusController: NSPopoverDelegate {
    func popoverDidClose(_ notification: Notification) {
        dismissTimer?.invalidate()
        dismissTimer = nil
        if let activityMonitor { NSEvent.removeMonitor(activityMonitor) }
        activityMonitor = nil
    }
}

/// Lets the NSStatusBarButton receive clicks while SwiftUI draws the cat.
private final class StatusButtonHostingView<Content: View>: NSHostingView<Content> {
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}
