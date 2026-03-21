import Foundation
import QuartzCore

@Observable
final class OnboardingViewModel {
    // MARK: - Step

    enum Step: Equatable {
        case welcome
        case explain
        case trial(Int) // 1, 2, 3
        case result

        var trialNumber: Int? {
            if case .trial(let n) = self { return n }
            return nil
        }
    }

    // MARK: - Coach Phase (within a trial)

    enum CoachPhase: Equatable {
        case fixation
        case waitingForStimulus
        case waitingForMask
        case respond
        case feedback
    }

    // MARK: - State

    private(set) var currentStep: Step = .welcome
    private(set) var coachPhase: CoachPhase = .fixation
    private(set) var currentStimulus: StimulusType = .car
    private(set) var phase: SessionPhase = .fixation
    private(set) var isCorrect: Bool?
    private(set) var reactionTimeMs: Double?
    private(set) var trialResults: [(correct: Bool, rt: Double)] = []

    private var responseStartTime: CFTimeInterval = 0

    // MARK: - Computed

    var averageRT: Double {
        guard !trialResults.isEmpty else { return 0 }
        return trialResults.map(\.rt).reduce(0, +) / Double(trialResults.count)
    }

    var correctCount: Int {
        trialResults.filter(\.correct).count
    }

    var showCoachForFixation: Bool {
        currentStep == .trial(1) && coachPhase == .fixation
    }

    var showCoachForRespond: Bool {
        guard case .trial(let n) = currentStep else { return false }
        return n <= 2 && coachPhase == .respond
    }

    var showTryYourself: Bool {
        currentStep == .trial(2) && coachPhase == .fixation
    }

    // MARK: - Navigation

    func advance() {
        switch currentStep {
        case .welcome:
            currentStep = .explain
        case .explain:
            currentStep = .trial(1)
            startTrial()
        case .trial(let n):
            if n < 3 {
                currentStep = .trial(n + 1)
                startTrial()
            } else {
                currentStep = .result
            }
        case .result:
            break
        }
    }

    func skip() {
        currentStep = .result
    }

    // MARK: - Trial Logic

    func startTrial() {
        currentStimulus = StimulusType.allCases.randomElement() ?? .car
        phase = .fixation
        coachPhase = .fixation
        isCorrect = nil
        reactionTimeMs = nil
    }

    func onMaskComplete() {
        phase = .response
        coachPhase = .respond
        responseStartTime = CACurrentMediaTime()
    }

    func respond(choice: StimulusType) {
        guard phase == .response else { return }

        let rt = (CACurrentMediaTime() - responseStartTime) * 1000.0
        let correct = (choice == currentStimulus)

        isCorrect = correct
        reactionTimeMs = rt
        trialResults.append((correct: correct, rt: rt))
        phase = .feedback
        coachPhase = .feedback
    }

    func onFeedbackComplete() {
        advance()
    }

    // MARK: - Stimulus Duration (fixed for onboarding, easier)

    var stimulusDurationFrames: Int { 25 } // ~417ms at 60fps — easy enough to see
}
