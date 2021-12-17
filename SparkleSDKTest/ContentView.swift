import SwiftUI

struct ContentView: View {
    @EnvironmentObject var updaterViewModel: UpdaterViewModel
    var body: some View {
        VStack {
            HStack {
                Text("Version \(Bundle.main.releaseVersionNumber!)")
                Text("Build \(Bundle.main.buildVersionNumber!)")
            }
            UpdaterView(model: updaterViewModel)
        }
        .frame(width: 200, height: 100)
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(UpdaterViewModel())
    }
}
