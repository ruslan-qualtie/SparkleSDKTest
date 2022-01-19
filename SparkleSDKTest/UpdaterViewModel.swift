import SwiftUI
import Sparkle
import AppCenterAnalytics

final class UpdaterViewModel: ObservableObject {
    @Published var canCheckForUpdates = false
    let lastUpdateCheckDate: String
    private let controller: SPUStandardUpdaterController

    init() {
        if let date = UserDefaults.standard.object(forKey: "SULastCheckTime") as? Date {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .medium
            lastUpdateCheckDate = dateFormatter.string(from: date)
        } else {
            lastUpdateCheckDate = "unavailable"
        }
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
