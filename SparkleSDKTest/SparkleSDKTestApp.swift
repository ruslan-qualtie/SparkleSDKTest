import SwiftUI

@main
struct SparkleSDKTestApp: App {
    @StateObject var updaterViewModel = UpdaterViewModel()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(updaterViewModel)
        }
        .commands {
            CommandGroup(after: .appInfo) {
                UpdaterView(model: updaterViewModel)
            }
        }
    }
}
