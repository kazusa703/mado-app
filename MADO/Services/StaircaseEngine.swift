import Foundation

@Observable
final class StaircaseEngine {
    // MARK: - Configuration

    private let initialDurationMs: Double
    private let initialStepMs: Double = 50.0
    private let reducedStepMs: Double = 17.0
    private let minDurationMs: Double
    private let maxDurationMs: Double = 500.0
    let targetReversals: Int = 9
    private let thresholdReversalCount: Int = 6 // Last N reversals for threshold

    // MARK: - State

    private(set) var currentDurationMs: Double
    private(set) var trialCount: Int = 0
    private(set) var reversalCount: Int = 0
    private(set) var isComplete: Bool = false
    private(set) var threshold: Double?

    private var consecutiveCorrect: Int = 0
    private var lastDirection: Direction?
    private var reversalValues: [Double] = []
    private var stepMs: Double
    private var hasFirstReversal = false

    private enum Direction {
        case down, up
    }

    // MARK: - Init

    init(taskType: Int, screenRefreshRate: Double = 60.0) {
        let frameDurationMs = 1000.0 / screenRefreshRate
        self.minDurationMs = frameDurationMs

        switch taskType {
        case 1:
            self.initialDurationMs = 333.0
        case 2, 3:
            self.initialDurationMs = 333.0 + 84.0
        default:
            self.initialDurationMs = 333.0
        }

        self.currentDurationMs = initialDurationMs
        self.stepMs = initialStepMs
    }

    // MARK: - Process Response

    func processResponse(isCorrect: Bool) {
        trialCount += 1

        if isCorrect {
            consecutiveCorrect += 1
            if consecutiveCorrect >= 2 {
                // 2-down: decrease duration (make harder)
                applyStep(direction: .down)
                consecutiveCorrect = 0
            }
        } else {
            // 1-up: increase duration (make easier)
            consecutiveCorrect = 0
            applyStep(direction: .up)
        }
    }

    private func applyStep(direction: Direction) {
        // Check for reversal
        if let last = lastDirection, last != direction {
            reversalCount += 1
            reversalValues.append(currentDurationMs)

            if !hasFirstReversal {
                hasFirstReversal = true
                stepMs = reducedStepMs
            }

            if reversalCount >= targetReversals {
                computeThreshold()
                return
            }
        }

        lastDirection = direction

        switch direction {
        case .down:
            currentDurationMs = max(minDurationMs, currentDurationMs - stepMs)
        case .up:
            currentDurationMs = min(maxDurationMs, currentDurationMs + stepMs)
        }
    }

    private func computeThreshold() {
        isComplete = true
        let count = min(thresholdReversalCount, reversalValues.count)
        let lastReversals = Array(reversalValues.suffix(count))
        threshold = lastReversals.reduce(0, +) / Double(lastReversals.count)
    }

    // MARK: - Frame Conversion

    func durationInFrames(refreshRate: Double) -> Int {
        let frameDuration = 1000.0 / refreshRate
        return max(1, Int(round(currentDurationMs / frameDuration)))
    }

    func reset() {
        currentDurationMs = initialDurationMs
        trialCount = 0
        reversalCount = 0
        isComplete = false
        threshold = nil
        consecutiveCorrect = 0
        lastDirection = nil
        reversalValues = []
        stepMs = initialStepMs
        hasFirstReversal = false
    }
}
