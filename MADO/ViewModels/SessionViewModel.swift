import Foundation
import QuartzCore

@Observable
final class SessionViewModel {
    // MARK: - Published State

    private(set) var phase: SessionPhase = .fixation
    private(set) var trialCount: Int = 0
    private(set) var currentStimulus: StimulusType = .car
    private(set) var isCorrect: Bool?
    private(set) var reactionTimeMs: Double?
    private(set) var isSessionComplete = false
    private(set) var isPaused = false
    private(set) var threshold: Double?
    private(set) var totalTrials: Int = 0
    private(set) var correctTrials: Int = 0

    var progressRatio: Double {
        guard staircase.targetReversals > 0 else { return 0 }
        return min(1.0, Double(staircase.reversalCount) / Double(9))
    }

    // MARK: - Private

    let staircase: StaircaseEngine
    private var responseStartTime: CFTimeInterval = 0
    private var sessionStartTime: Date?
    private var trials: [TrialRecord] = []
    private let taskType: Int

    // MARK: - Init

    init(taskType: Int = 1) {
        self.taskType = taskType
        staircase = StaircaseEngine(taskType: taskType)
    }

    // MARK: - Session Control

    func startSession() {
        staircase.reset()
        trialCount = 0
        totalTrials = 0
        correctTrials = 0
        isSessionComplete = false
        isPaused = false
        trials = []
        sessionStartTime = Date()
        startNextTrial()
    }

    func startNextTrial() {
        guard !staircase.isComplete else {
            completeSession()
            return
        }

        trialCount += 1
        currentStimulus = StimulusType.allCases.randomElement() ?? .car
        phase = .fixation
        isCorrect = nil
        reactionTimeMs = nil
    }

    func onMaskComplete() {
        phase = .response
        responseStartTime = CACurrentMediaTime()
    }

    func respond(choice: StimulusType) {
        guard phase == .response else { return }

        let rt = (CACurrentMediaTime() - responseStartTime) * 1000.0
        let correct = (choice == currentStimulus)

        isCorrect = correct
        reactionTimeMs = rt
        totalTrials += 1
        if correct { correctTrials += 1 }

        staircase.processResponse(isCorrect: correct)

        // Save trial
        var trial = TrialRecord(
            sessionId: 0, // Will be updated when session saves
            trialNumber: trialCount,
            stimulusDurationMs: staircase.currentDurationMs,
            isCorrect: correct,
            reactionTimeMs: rt
        )
        trials.append(trial)

        phase = .feedback
    }

    func onFeedbackComplete() {
        if staircase.isComplete {
            completeSession()
        } else {
            startNextTrial()
        }
    }

    func togglePause() {
        isPaused.toggle()
    }

    // MARK: - Session Completion

    private func completeSession() {
        isSessionComplete = true
        threshold = staircase.threshold

        let duration = sessionStartTime.map { Date().timeIntervalSince($0) } ?? 0

        let trialsSnapshot = trials
        let thresholdValue = staircase.threshold ?? staircase.currentDurationMs
        let tt = totalTrials
        let ct = correctTrials
        let type = taskType

        Task {
            let session = SessionRecord(
                taskType: type,
                threshold: thresholdValue,
                date: Date(),
                duration: duration,
                totalTrials: tt,
                correctTrials: ct
            )

            do {
                let saved = try await DatabaseService.shared.saveSession(session)

                if let sessionId = saved.id {
                    for trial in trialsSnapshot {
                        var t = trial
                        t.sessionId = sessionId
                        try await DatabaseService.shared.saveTrial(t)
                    }
                }
            } catch {
                print("Failed to save session: \(error)")
            }
        }

        UserSettings.shared.sessionsToday += 1
    }

    var currentDurationMs: Double {
        staircase.currentDurationMs
    }
}
