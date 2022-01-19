import SwiftUI
import AppCenterAnalytics
import AppCenterCrashes

struct ContentView: View {
    @EnvironmentObject var updaterViewModel: UpdaterViewModel
    var body: some View {
        VStack {
            HStack {
                Text("Version \(Bundle.main.releaseVersionNumber!)")
                Text("Build \(Bundle.main.buildVersionNumber!)")
            }
            Text("Last update check: \(updaterViewModel.lastUpdateCheckDate)")
            UpdaterView(model: updaterViewModel)
            Button("Simulate Event") {
                Analytics.trackEvent("Simulated Event")
            }
            Button("Simulate Crash") {
                Crashes.generateTestCrash()
            }
        }
        .frame(width: 300, height: 100)
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(UpdaterViewModel())
    }
}
