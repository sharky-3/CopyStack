import SwiftUI

@main
struct CopyCatApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No real window — this app lives entirely in the menu bar.
        // Settings{} gives SwiftUI a valid Scene without showing anything.
        Settings {
            EmptyView()
        }
    }
}
