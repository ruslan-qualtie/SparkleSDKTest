import SwiftUI

// This additional view is needed for the disabled state on the menu item to work properly before Monterey.
// See https://stackoverflow.com/questions/68553092/menu-not-updating-swiftui-bug for more information

struct UpdaterView: View {
    @ObservedObject var model: UpdaterViewModel
    
    var body: some View {
        Button("Check For Updates…", action: model.checkForUpdates)
            .disabled(!model.canCheckForUpdates)
    }
}
