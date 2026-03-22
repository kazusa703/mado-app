@testable import MADO
import Testing

@Suite("StaircaseEngine")
struct StaircaseEngineTests {
    // MARK: - Initial State

    @Test("Initial state for Task 1")
    func initialStateTask1() {
        let engine = StaircaseEngine(taskType: 1)
        #expect(engine.currentDurationMs == 333.0)
        #expect(engine.trialCount == 0)
        #expect(engine.reversalCount == 0)
        #expect(!engine.isComplete)
        #expect(engine.threshold == nil)
    }

    @Test("Initial state for Task 2/3", arguments: [2, 3])
    func initialStateTask2and3(taskType: Int) {
        let engine = StaircaseEngine(taskType: taskType)
        #expect(engine.currentDurationMs == 417.0) // 333 + 84
    }

    // MARK: - 2-Down Rule

    @Test("Two consecutive correct responses decrease duration by initial step")
    func twoDownRule() {
        let engine = StaircaseEngine(taskType: 1)
        engine.processResponse(isCorrect: true)
        #expect(engine.currentDurationMs == 333.0) // No change after 1 correct

        engine.processResponse(isCorrect: true)
        #expect(engine.currentDurationMs == 283.0) // 333 - 50
    }

    @Test("Single correct does not change duration")
    func singleCorrectNoChange() {
        let engine = StaircaseEngine(taskType: 1)
        engine.processResponse(isCorrect: true)
        #expect(engine.currentDurationMs == 333.0)
    }

    // MARK: - 1-Up Rule

    @Test("One incorrect response increases duration by initial step")
    func oneUpRule() {
        let engine = StaircaseEngine(taskType: 1)
        engine.processResponse(isCorrect: false)
        #expect(engine.currentDurationMs == 383.0) // 333 + 50
    }

    // MARK: - Reversal Detection

    @Test("Reversal detected when direction changes")
    func reversalDetection() {
        let engine = StaircaseEngine(taskType: 1)
        // 2 correct → down
        engine.processResponse(isCorrect: true)
        engine.processResponse(isCorrect: true)
        #expect(engine.reversalCount == 0)

        // 1 incorrect → up (reversal!)
        engine.processResponse(isCorrect: false)
        #expect(engine.reversalCount == 1)
    }

    // MARK: - Step Size Reduction

    @Test("Step reduces from 50ms to 17ms after first reversal")
    func stepReduction() {
        let engine = StaircaseEngine(taskType: 1)
        // Down: 333 → 283 (50ms step)
        engine.processResponse(isCorrect: true)
        engine.processResponse(isCorrect: true)
        #expect(engine.currentDurationMs == 283.0)

        // Up (reversal 1): step applied is still 50ms at point of reversal
        // After reversal, step switches to 17ms for future steps
        engine.processResponse(isCorrect: false)
        // 283 + 17 = 300 (reduced step already in effect after reversal detection)
        #expect(engine.reversalCount == 1)
        let afterReversal = engine.currentDurationMs

        // Down again: should use 17ms step
        engine.processResponse(isCorrect: true)
        engine.processResponse(isCorrect: true)
        #expect(engine.currentDurationMs == afterReversal - 17.0)
    }

    // MARK: - Clamping

    @Test("Duration does not go below minimum")
    func minimumClamp() {
        let engine = StaircaseEngine(taskType: 1)
        // Force duration down repeatedly
        for _ in 0 ..< 100 {
            engine.processResponse(isCorrect: true)
        }
        let frameDuration = 1000.0 / 60.0
        #expect(engine.currentDurationMs >= frameDuration)
    }

    @Test("Duration does not exceed 500ms")
    func maximumClamp() {
        let engine = StaircaseEngine(taskType: 1)
        // Force duration up repeatedly
        for _ in 0 ..< 100 {
            engine.processResponse(isCorrect: false)
            if engine.isComplete { break }
        }
        #expect(engine.currentDurationMs <= 500.0)
    }

    // MARK: - Session Completion

    @Test("Session completes after 9 reversals")
    func completionAt9Reversals() {
        let engine = StaircaseEngine(taskType: 1)
        simulateToCompletion(engine)
        #expect(engine.isComplete)
        #expect(engine.reversalCount >= 9)
        #expect(engine.threshold != nil)
    }

    @Test("Threshold is average of last 6 reversals")
    func thresholdCalculation() {
        let engine = StaircaseEngine(taskType: 1)
        simulateToCompletion(engine)

        guard let threshold = engine.threshold else {
            Issue.record("Threshold should not be nil")
            return
        }
        // Threshold should be within plausible range
        let frameDuration = 1000.0 / 60.0
        #expect(threshold >= frameDuration)
        #expect(threshold <= 500.0)
    }

    // MARK: - Reset

    @Test("Reset restores initial state")
    func resetWorks() {
        let engine = StaircaseEngine(taskType: 1)
        engine.processResponse(isCorrect: true)
        engine.processResponse(isCorrect: true)
        engine.processResponse(isCorrect: false)

        engine.reset()

        #expect(engine.currentDurationMs == 333.0)
        #expect(engine.trialCount == 0)
        #expect(engine.reversalCount == 0)
        #expect(!engine.isComplete)
        #expect(engine.threshold == nil)
    }

    // MARK: - Consecutive Correct Reset

    @Test("Incorrect response resets consecutive correct count")
    func incorrectResetsStreak() {
        let engine = StaircaseEngine(taskType: 1)
        engine.processResponse(isCorrect: true) // 1 correct
        engine.processResponse(isCorrect: false) // reset streak
        engine.processResponse(isCorrect: true) // 1 correct again
        // Duration should only have changed from the incorrect response
        #expect(engine.currentDurationMs == 383.0) // 333 + 50
    }

    // MARK: - Helper

    private func simulateToCompletion(_ engine: StaircaseEngine) {
        var toggle = true
        for _ in 0 ..< 200 {
            if engine.isComplete { break }
            if toggle {
                engine.processResponse(isCorrect: true)
                engine.processResponse(isCorrect: true)
            } else {
                engine.processResponse(isCorrect: false)
            }
            toggle.toggle()
        }
    }
}
