import SwiftUI
import Charts

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @State private var showSession = false
    @Bindable var theme = ThemeManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    windowCard
                    startButton
                    statsRow
                    taskListSection
                    if !viewModel.thresholdHistory.isEmpty {
                        miniChart
                    }
                    disclaimerFooter
                }
                .padding()
            }
            .background(theme.bg)
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: $showSession) {
                SessionView(onDismiss: {
                    showSession = false
                    Task { await viewModel.load() }
                })
            }
        }
        .task { await viewModel.load() }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(Date(), style: .date)
                    .font(.subheadline)
                    .foregroundStyle(theme.textSub)
                Text("MADO")
                    .font(.largeTitle.bold())
                    .foregroundStyle(theme.text)
            }
            Spacer()
            if viewModel.streakDays > 0 {
                Label("\(viewModel.streakDays)", systemImage: "flame.fill")
                    .font(.headline)
                    .foregroundStyle(theme.gold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(theme.goldSoft, in: Capsule())
            }
        }
    }

    // MARK: - Window Card

    private var windowCard: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(theme.accentSoft)
                    .frame(width: 120, height: 120)
                Circle()
                    .fill(theme.accent.opacity(0.3))
                    .frame(width: 80, height: 80)
                Circle()
                    .fill(theme.accent)
                    .frame(width: 40, height: 40)

                if viewModel.latestThreshold != nil {
                    Text("\(viewModel.windowScore)")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                } else {
                    Image(systemName: "eye.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
            }

            if viewModel.latestThreshold != nil {
                Text(String(localized: "home_window_score"))
                    .font(.headline)
                    .foregroundStyle(theme.text)

                if let improvement = viewModel.improvementPercent {
                    Text("\(Int(improvement))% \(String(localized: "home_improved"))")
                        .font(.subheadline)
                        .foregroundStyle(theme.teal)
                }
            } else {
                Text(String(localized: "home_welcome"))
                    .font(.headline)
                    .foregroundStyle(theme.text)
                Text(String(localized: "home_welcome_detail"))
                    .font(.subheadline)
                    .foregroundStyle(theme.textSub)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .background(theme.bgCard, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: theme.cardShadow, radius: 8, y: 4)
    }

    // MARK: - Start Button

    private var startButton: some View {
        Button {
            showSession = true
        } label: {
            HStack {
                Image(systemName: "play.fill")
                Text(String(localized: "home_start_training"))
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(theme.accent, in: RoundedRectangle(cornerRadius: 14))
            .foregroundStyle(.white)
        }
        .disabled(!UserSettings.shared.canStartSession)
        .opacity(UserSettings.shared.canStartSession ? 1.0 : 0.5)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: showSession)
        .accessibilityLabel(String(localized: "home_start_training"))
        .accessibilityHint(UserSettings.shared.canStartSession
            ? String(localized: "accessibility_start_hint")
            : String(localized: "accessibility_limit_reached"))
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 0) {
            statItem(
                value: "\(viewModel.streakDays)",
                label: String(localized: "home_streak_days"),
                icon: "flame.fill"
            )
            Divider().frame(height: 40)
            statItem(
                value: "\(viewModel.sessionsToday)",
                label: String(localized: "home_today_sessions"),
                icon: "checkmark.circle.fill"
            )
            Divider().frame(height: 40)
            statItem(
                value: viewModel.bestThreshold.map { "\(Int($0))ms" } ?? "—",
                label: String(localized: "home_best_record"),
                icon: "trophy.fill"
            )
        }
        .padding(.vertical, 16)
        .background(theme.bgCard, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: theme.cardShadow, radius: 4, y: 2)
    }

    private func statItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(theme.accent)
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(theme.text)
            Text(label)
                .font(.caption)
                .foregroundStyle(theme.textSub)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Task List

    private var taskListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "home_tasks"))
                .font(.headline)
                .foregroundStyle(theme.text)

            taskRow(
                number: 1,
                name: String(localized: "task1_name"),
                threshold: viewModel.latestThreshold,
                isLocked: false
            )

            taskRow(
                number: 2,
                name: String(localized: "task2_name"),
                threshold: nil,
                isLocked: true
            )

            taskRow(
                number: 3,
                name: String(localized: "task3_name"),
                threshold: nil,
                isLocked: true
            )
        }
    }

    private func taskRow(number: Int, name: String, threshold: Double?, isLocked: Bool) -> some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(isLocked ? theme.textMuted : theme.accent, in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.body)
                    .foregroundStyle(isLocked ? theme.textMuted : theme.text)
                if let threshold {
                    Text("\(Int(threshold))ms")
                        .font(.caption)
                        .foregroundStyle(theme.textSub)
                }
            }

            Spacer()

            if isLocked {
                Image(systemName: "lock.fill")
                    .foregroundStyle(theme.textMuted)
            }
        }
        .padding(12)
        .background(theme.bgCard, in: RoundedRectangle(cornerRadius: 10))
        .shadow(color: theme.cardShadow, radius: 2, y: 1)
        .opacity(isLocked ? 0.6 : 1.0)
    }

    // MARK: - Mini Chart

    private var miniChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "home_threshold_trend"))
                .font(.headline)
                .foregroundStyle(theme.text)

            Chart(viewModel.thresholdHistory) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Threshold", point.threshold)
                )
                .foregroundStyle(theme.accent)
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Threshold", point.threshold)
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [theme.accent.opacity(0.2), theme.accent.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        Text("\(value.as(Int.self) ?? 0)ms")
                            .font(.caption2)
                            .foregroundStyle(theme.textSub)
                    }
                }
            }
            .chartXAxis(.hidden)
            .frame(height: 150)
        }
        .padding()
        .background(theme.bgCard, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: theme.cardShadow, radius: 4, y: 2)
    }

    // MARK: - Disclaimer Footer

    private var disclaimerFooter: some View {
        Text(String(localized: "settings_disclaimer"))
            .font(.caption2)
            .foregroundStyle(theme.textMuted)
            .multilineTextAlignment(.center)
            .padding(.top, 8)
    }
}
