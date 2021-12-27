import AppCenter
import AppCenterAnalytics
import AppCenterCrashes
import SwiftUI

@main
struct SparkleSDKTestApp: App {
    @StateObject var updaterViewModel = UpdaterViewModel()
    
    init() {
        AppCenter.start(withAppSecret: "23b226e2-5cd2-46b9-bfe5-59d5787a356c", services:[
            Analytics.self,
            Crashes.self
        ])
    }
    
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
