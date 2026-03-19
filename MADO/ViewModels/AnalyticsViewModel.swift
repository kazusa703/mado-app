import Foundation

@Observable
final class AnalyticsViewModel {
    private(set) var sessions: [SessionRecord] = []
    private(set) var thresholdPoints: [ThresholdPoint] = []
    private(set) var reactionTimePoints: [RTPoint] = []
    private(set) var isLoading = true

    struct ThresholdPoint: Identifiable {
        let id = UUID()
        let date: Date
        let threshold: Double
    }

    struct RTPoint: Identifiable {
        let id = UUID()
        let trialNumber: Int
        let reactionTime: Double
        let isCorrect: Bool
    }

    func load() async {
        do {
            sessions = try await DatabaseService.shared.fetchSessions(taskType: 1, limit: 50)
            thresholdPoints = sessions.reversed().map {
                ThresholdPoint(date: $0.date, threshold: $0.threshold)
            }

            // Load RT data from latest session
            if let latest = sessions.first, let id = latest.id {
                let trials = try await DatabaseService.shared.fetchTrials(sessionId: id)
                reactionTimePoints = trials.map {
                    RTPoint(trialNumber: $0.trialNumber, reactionTime: $0.reactionTimeMs, isCorrect: $0.isCorrect)
                }
            }
        } catch {
            print("Failed to load analytics: \(error)")
        }
        isLoading = false
    }
}
