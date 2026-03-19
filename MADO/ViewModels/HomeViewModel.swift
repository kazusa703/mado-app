import Foundation

@Observable
final class HomeViewModel {
    private(set) var streakDays: Int = 0
    private(set) var sessionsToday: Int = 0
    private(set) var bestThreshold: Double?
    private(set) var latestThreshold: Double?
    private(set) var thresholdHistory: [ThresholdPoint] = []
    private(set) var isLoading = true

    struct ThresholdPoint: Identifiable {
        let id = UUID()
        let date: Date
        let threshold: Double
    }

    func load() async {
        do {
            streakDays = try await DatabaseService.shared.streakDays()
            sessionsToday = UserSettings.shared.sessionsToday
            bestThreshold = try await DatabaseService.shared.bestThreshold(taskType: 1)

            let latest = try await DatabaseService.shared.fetchLatestSession(taskType: 1)
            latestThreshold = latest?.threshold

            let sessions = try await DatabaseService.shared.fetchSessions(taskType: 1, limit: 20)
            thresholdHistory = sessions.reversed().map {
                ThresholdPoint(date: $0.date, threshold: $0.threshold)
            }
        } catch {
            print("Failed to load home data: \(error)")
        }

        isLoading = false
    }

    var improvementPercent: Double? {
        guard let first = thresholdHistory.first?.threshold,
              let last = thresholdHistory.last?.threshold,
              thresholdHistory.count >= 2,
              first > 0 else { return nil }
        return ((first - last) / first) * 100
    }

    var windowScore: Int {
        guard let threshold = latestThreshold else { return 0 }
        // Convert threshold to a 0-100 score (lower threshold = higher score)
        return max(0, min(100, Int(100 - (threshold / 5.0))))
    }
}
