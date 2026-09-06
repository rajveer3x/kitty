import SwiftUI

@main
struct KittyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // A settings scene satisfies the SwiftUI app lifecycle without opening
        // a window. The application is an LSUIElement, so it stays menu-bar only.
        Settings { EmptyView() }
    }
}
