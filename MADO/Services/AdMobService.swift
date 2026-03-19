import SwiftUI

// AdMob integration placeholder
// Real implementation requires Google Mobile Ads SDK via SPM
// For now, use test IDs and placeholder UI

enum AdUnitID {
    #if DEBUG
    static let interstitial = "ca-app-pub-3940256099942544/4411468910" // Google test ID
    #else
    static let interstitial = "ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX" // Replace with real ID
    #endif
}

@Observable
final class AdMobService {
    static let shared = AdMobService()

    private(set) var isAdReady = false
    private(set) var isShowingAd = false

    private init() {}

    func loadInterstitial() {
        // Will be implemented when Google Mobile Ads SDK is integrated
        // For now, simulate ad availability
        isAdReady = true
    }

    func showInterstitialIfNeeded() -> Bool {
        guard UserSettings.shared.canShowAd else { return false }
        guard isAdReady else { return false }

        isShowingAd = true
        UserSettings.shared.adsShownToday += 1

        // Simulate ad display completion
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.5))
            self.isShowingAd = false
            self.loadInterstitial()
        }

        return true
    }
}
