import SwiftUI
import Sparkle
import AppCenterAnalytics

final class UpdaterViewModel: ObservableObject {
    @Published var canCheckForUpdates = false
    private let controller: SPUStandardUpdaterController

    init() {
        controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        controller.updater
            .publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }

    func checkForUpdates() {
        controller.checkForUpdates(nil)
        Analytics.trackEvent("Сheck For Updates")
    }
}
