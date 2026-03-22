import Foundation
import QuartzCore

@Observable
final class OnboardingViewModel {
    // MARK: - Step

    static let totalTrials = 5

    enum Step: Equatable {
        case welcome
        case explain
        case trial(Int) // 1...5
        case result

        var trialNumber: Int? {
            if case let .trial(n) = self { return n }
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
        guard case let .trial(n) = currentStep else { return false }
        return n <= 3 && coachPhase == .respond
    }

    var showTryYourself: Bool {
        currentStep == .trial(3) && coachPhase == .fixation
    }

    // MARK: - Navigation

    func advance() {
        switch currentStep {
        case .welcome:
            currentStep = .explain
        case .explain:
            currentStep = .trial(1)
            startTrial()
        case let .trial(n):
            if n < Self.totalTrials {
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

    // MARK: - Stimulus Duration (progressively shorter to show difficulty scaling)

    var stimulusDurationMs: Double {
        guard case let .trial(n) = currentStep else { return 417.0 }
        // Trial 1: 500ms, 2: 417ms, 3: 333ms, 4: 250ms, 5: 200ms
        switch n {
        case 1: return 500.0
        case 2: return 417.0
        case 3: return 333.0
        case 4: return 250.0
        default: return 200.0
        }
    }
}
