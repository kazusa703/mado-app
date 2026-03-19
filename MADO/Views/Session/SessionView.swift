import SwiftUI
import MetalKit
import StoreKit

struct SessionView: View {
    @State private var viewModel = SessionViewModel()
    @State private var renderer: StimulusRenderer?
    @State private var showPauseAlert = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.requestReview) private var requestReview

    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            ThemeColors.Session.bg.ignoresSafeArea()

            if viewModel.isSessionComplete {
                sessionCompleteView
            } else {
                sessionActiveView
            }
        }
        .preferredColorScheme(.dark)
        .statusBarHidden(true)
        .onAppear { setupRenderer() }
    }

    // MARK: - Active Session

    private var sessionActiveView: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                Text(String(localized: "task1_name"))
                    .font(.subheadline.bold())
                    .foregroundStyle(ThemeColors.Session.text)

                Spacer()

                Text(String(localized: "session_trial \(viewModel.trialCount)"))
                    .font(.caption)
                    .foregroundStyle(ThemeColors.Session.textMuted)

                Button {
                    showPauseAlert = true
                } label: {
                    Image(systemName: "pause.fill")
                        .font(.body)
                        .foregroundStyle(ThemeColors.Session.textMuted)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(String(localized: "session_pause_title"))
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // Progress bar
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 2)
                    .fill(ThemeColors.Session.border)
                    .frame(height: 4)
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(ThemeColors.Session.fixation)
                            .frame(
                                width: geo.size.width * viewModel.progressRatio,
                                height: 4
                            )
                            .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: viewModel.progressRatio)
                    }
            }
            .frame(height: 4)
            .padding(.horizontal)
            .padding(.top, 8)

            // Metal view
            if let renderer {
                SessionMetalView(renderer: renderer)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding()
            }

            // Response buttons
            if viewModel.phase == .response {
                responseButtons
            } else if viewModel.phase == .feedback {
                feedbackView
            }

            Spacer()
        }
        .confirmationDialog(
            String(localized: "session_pause_title"),
            isPresented: $showPauseAlert,
            titleVisibility: .visible
        ) {
            Button(String(localized: "session_resume")) {}
            Button(String(localized: "session_quit"), role: .destructive) {
                onDismiss()
            }
        }
    }

    // MARK: - Response Buttons

    private var responseButtons: some View {
        HStack(spacing: 24) {
            responseButton(type: .car)
            responseButton(type: .truck)
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 16)
        .transition(.opacity)
    }

    private func responseButton(type: StimulusType) -> some View {
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
        .sensoryFeedback(.impact(flexibility: .soft), trigger: viewModel.trialCount)
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
                try? await Task.sleep(for: .milliseconds(600))
                viewModel.onFeedbackComplete()
                if !viewModel.isSessionComplete {
                    renderer?.startTrial(
                        stimulus: viewModel.currentStimulus,
                        durationFrames: viewModel.durationFrames
                    )
                }
            }
        }
    }

    // MARK: - Session Complete

    private var sessionCompleteView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(ThemeColors.Session.fixation)

            Text(String(localized: "session_complete"))
                .font(.title.bold())
                .foregroundStyle(ThemeColors.Session.text)

            if let threshold = viewModel.threshold {
                VStack(spacing: 8) {
                    Text(String(localized: "session_threshold"))
                        .font(.subheadline)
                        .foregroundStyle(ThemeColors.Session.textMuted)
                    Text("\(Int(threshold))ms")
                        .font(.system(size: 48, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(ThemeColors.Session.text)
                }
            }

            HStack(spacing: 32) {
                VStack {
                    Text("\(viewModel.totalTrials)")
                        .font(.title2.bold())
                        .foregroundStyle(ThemeColors.Session.text)
                    Text(String(localized: "session_total_trials"))
                        .font(.caption)
                        .foregroundStyle(ThemeColors.Session.textMuted)
                }
                VStack {
                    Text("\(viewModel.correctTrials)/\(viewModel.totalTrials)")
                        .font(.title2.bold())
                        .foregroundStyle(ThemeColors.Session.text)
                    Text(String(localized: "session_accuracy"))
                        .font(.caption)
                        .foregroundStyle(ThemeColors.Session.textMuted)
                }
            }

            Spacer()

            Button {
                // Show ad for free users
                _ = AdMobService.shared.showInterstitialIfNeeded()

                // Request review after 3rd completed session
                let totalSessions = UserSettings.shared.sessionsToday
                if totalSessions == 3 {
                    requestReview()
                }

                onDismiss()
            } label: {
                Text(String(localized: "session_return_home"))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(ThemeColors.Session.fixation, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Setup

    private func setupRenderer() {
        // Create a temporary MTKView just for pipeline init (SessionMetalView creates the real one)
        let tempView = MTKView()
        tempView.device = MTLCreateSystemDefaultDevice()
        guard let r = StimulusRenderer(mtkView: tempView) else { return }

        renderer = r
        r.onMaskComplete = { [weak viewModel] in
            viewModel?.onMaskComplete()
        }
        viewModel.startSession()
        r.startTrial(
            stimulus: viewModel.currentStimulus,
            durationFrames: viewModel.durationFrames
        )
    }
}
