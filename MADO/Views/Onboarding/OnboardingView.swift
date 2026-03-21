import SwiftUI
import MetalKit

struct OnboardingView: View {
    @State private var viewModel = OnboardingViewModel()
    @State private var renderer: StimulusRenderer?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let onComplete: () -> Void

    var body: some View {
        ZStack {
            ThemeColors.Session.bg.ignoresSafeArea()

            switch viewModel.currentStep {
            case .welcome:
                welcomeStep
            case .explain:
                explainStep
            case .trial:
                trialStep
            case .result:
                resultStep
            }

            // Skip button (always visible except on result)
            if viewModel.currentStep != .result {
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            viewModel.skip()
                        } label: {
                            Text(String(localized: "onboarding_skip"))
                                .font(.subheadline)
                                .foregroundStyle(ThemeColors.Session.textMuted)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                        }
                    }
                    Spacer()
                }
                .padding(.top, 8)
            }
        }
        .preferredColorScheme(.dark)
        .statusBarHidden(true)
    }

    // MARK: - Welcome Step

    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Spacer()

            // Window animation
            ZStack {
                Circle()
                    .fill(Color(hex: "4CA6E8").opacity(0.1))
                    .frame(width: 160, height: 160)
                Circle()
                    .fill(Color(hex: "4CA6E8").opacity(0.25))
                    .frame(width: 100, height: 100)
                Circle()
                    .fill(Color(hex: "4CA6E8"))
                    .frame(width: 50, height: 50)
                Image(systemName: "eye.fill")
                    .font(.title)
                    .foregroundStyle(.white)
            }

            Text(String(localized: "onboarding_welcome_title"))
                .font(.title.bold())
                .foregroundStyle(ThemeColors.Session.text)

            Text(String(localized: "onboarding_welcome_body"))
                .font(.body)
                .foregroundStyle(ThemeColors.Session.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            Button {
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
                    viewModel.advance()
                }
            } label: {
                Text(String(localized: "onboarding_start"))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(hex: "4CA6E8"), in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }

    // MARK: - Explain Step

    private var explainStep: some View {
        VStack(spacing: 32) {
            Spacer()

            Text(String(localized: "onboarding_explain_title"))
                .font(.title2.bold())
                .foregroundStyle(ThemeColors.Session.text)

            // Car vs Truck illustration
            HStack(spacing: 40) {
                VStack(spacing: 12) {
                    Image(systemName: "car.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Color(hex: "4CA6E8"))
                    Text(String(localized: "stimulus_car"))
                        .font(.headline)
                        .foregroundStyle(ThemeColors.Session.text)
                }

                Text(String(localized: "onboarding_or"))
                    .font(.title3)
                    .foregroundStyle(ThemeColors.Session.textMuted)

                VStack(spacing: 12) {
                    Image(systemName: "truck.box.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Color(hex: "4CA6E8"))
                    Text(String(localized: "stimulus_truck"))
                        .font(.headline)
                        .foregroundStyle(ThemeColors.Session.text)
                }
            }

            Text(String(localized: "onboarding_explain_body"))
                .font(.body)
                .foregroundStyle(ThemeColors.Session.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            Button {
                setupRenderer()
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
                    viewModel.advance()
                }
            } label: {
                Text(String(localized: "onboarding_try_it"))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(hex: "4CA6E8"), in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }

    // MARK: - Trial Step

    private var trialStep: some View {
        VStack(spacing: 0) {
            // Trial indicator
            HStack {
                if let n = viewModel.currentStep.trialNumber {
                    Text(String(localized: "onboarding_trial \(n)"))
                        .font(.subheadline.bold())
                        .foregroundStyle(ThemeColors.Session.text)
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 44)

            // Progress dots
            HStack(spacing: 8) {
                ForEach(1...3, id: \.self) { i in
                    Circle()
                        .fill(trialDotColor(for: i))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 8)

            // Metal view
            ZStack {
                if let renderer {
                    SessionMetalView(renderer: renderer)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding()
                }

                // Coach marks overlay
                if viewModel.showCoachForFixation {
                    VStack {
                        Spacer()
                        CoachMarkView(
                            text: String(localized: "onboarding_coach_fixation"),
                            position: .top
                        )
                        .padding(.bottom, 40)
                    }
                }

                if viewModel.showTryYourself {
                    VStack {
                        CoachMarkView(
                            text: String(localized: "onboarding_coach_try_yourself"),
                            position: .bottom,
                            showPulse: false
                        )
                        .padding(.top, 40)
                        Spacer()
                    }
                }
            }

            // Response buttons or feedback
            if viewModel.phase == .response {
                responseButtons

                if viewModel.showCoachForRespond {
                    CoachMarkView(
                        text: String(localized: "onboarding_coach_respond"),
                        position: .top
                    )
                    .padding(.bottom, 8)
                }
            } else if viewModel.phase == .feedback {
                feedbackView
            }

            Spacer()
        }
    }

    private func trialDotColor(for index: Int) -> Color {
        guard let current = viewModel.currentStep.trialNumber else {
            return ThemeColors.Session.border
        }
        if index < current {
            return Color(hex: "4CA6E8")
        } else if index == current {
            return Color(hex: "4CA6E8").opacity(0.6)
        } else {
            return ThemeColors.Session.border
        }
    }

    // MARK: - Response Buttons

    private var responseButtons: some View {
        HStack(spacing: 24) {
            onboardingResponseButton(type: .car)
            onboardingResponseButton(type: .truck)
        }
        .padding(.horizontal, 32)
        .transition(.opacity)
    }

    private func onboardingResponseButton(type: StimulusType) -> some View {
        Button {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.15)) {
                viewModel.respond(choice: type)
                renderer?.showResponseFeedback(correct: viewModel.isCorrect ?? false)
            }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: type == .car ? "car.fill" : "truck.box.fill")
                    .font(.title)
                Text(type.label)
                    .font(.subheadline.bold())
            }
            .foregroundStyle(ThemeColors.Session.text)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(ThemeColors.Session.surface, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(ThemeColors.Session.border, lineWidth: 1)
            )
        }
        .sensoryFeedback(.impact(flexibility: .soft), trigger: viewModel.trialResults.count)
    }

    // MARK: - Feedback

    private var feedbackView: some View {
        HStack(spacing: 16) {
            Image(systemName: viewModel.isCorrect == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.title)
                .foregroundStyle(viewModel.isCorrect == true ? Color(hex: "34C759") : Color(hex: "FF453A"))

            if let rt = viewModel.reactionTimeMs {
                Text("\(Int(rt))ms")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(ThemeColors.Session.textMuted)
            }
        }
        .padding(.bottom, 16)
        .onAppear {
            Task {
                try? await Task.sleep(for: .milliseconds(800))
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
                    viewModel.onFeedbackComplete()
                }
                // Start next trial if still in trial step
                if case .trial = viewModel.currentStep {
                    renderer?.startTrial(
                        stimulus: viewModel.currentStimulus,
                        durationFrames: viewModel.stimulusDurationFrames
                    )
                }
            }
        }
    }

    // MARK: - Result Step

    private var resultStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 56))
                .foregroundStyle(Color(hex: "E8C84C"))

            Text(String(localized: "onboarding_result_title"))
                .font(.title2.bold())
                .foregroundStyle(ThemeColors.Session.text)

            if viewModel.averageRT > 0 {
                Text("\(Int(viewModel.averageRT))ms")
                    .font(.system(size: 56, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(Color(hex: "4CA6E8"))

                Text("\(viewModel.correctCount)/\(viewModel.trialResults.count) \(String(localized: "onboarding_correct"))")
                    .font(.headline)
                    .foregroundStyle(ThemeColors.Session.textMuted)
            }

            Text(String(localized: "onboarding_result_body"))
                .font(.body)
                .foregroundStyle(ThemeColors.Session.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            Button {
                onComplete()
            } label: {
                Text(String(localized: "onboarding_result_cta"))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(hex: "4CA6E8"), in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
            .sensoryFeedback(.impact(flexibility: .soft), trigger: true)
        }
    }

    // MARK: - Setup

    private func setupRenderer() {
        let tempView = MTKView()
        tempView.device = MTLCreateSystemDefaultDevice()
        guard let r = StimulusRenderer(mtkView: tempView) else { return }

        renderer = r
        r.onMaskComplete = { [weak viewModel] in
            viewModel?.onMaskComplete()
        }
        r.startTrial(
            stimulus: viewModel.currentStimulus,
            durationFrames: viewModel.stimulusDurationFrames
        )
    }
}
