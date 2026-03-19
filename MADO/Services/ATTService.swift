import AppTrackingTransparency

enum ATTService {
    static func requestIfNeeded() {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }

        Task { @MainActor in
            // Delay slightly so the app UI is fully presented
            try? await Task.sleep(for: .seconds(1))
            await ATTrackingManager.requestTrackingAuthorization()
        }
    }
}
