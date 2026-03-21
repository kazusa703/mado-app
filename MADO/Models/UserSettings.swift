import Foundation

@Observable
final class UserSettings {
    static let shared = UserSettings()

    var isPro: Bool {
        get { UserDefaults.standard.bool(forKey: "isPro") }
        set { UserDefaults.standard.set(newValue, forKey: "isPro") }
    }

    var sessionsToday: Int {
        get { UserDefaults.standard.integer(forKey: "sessionsToday_\(Self.todayKey)") }
        set { UserDefaults.standard.set(newValue, forKey: "sessionsToday_\(Self.todayKey)") }
    }

    var adsShownToday: Int {
        get { UserDefaults.standard.integer(forKey: "adsToday_\(Self.todayKey)") }
        set { UserDefaults.standard.set(newValue, forKey: "adsToday_\(Self.todayKey)") }
    }

    var canShowAd: Bool {
        !isPro && adsShownToday < 2
    }

    var canStartSession: Bool {
        isPro || sessionsToday < 1
    }

    private static var todayKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: Date())
    }

    var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") }
        set { UserDefaults.standard.set(newValue, forKey: "hasCompletedOnboarding") }
    }

    private init() {}
}
