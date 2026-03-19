import SwiftUI
import Charts

struct AnalyticsView: View {
    @State private var viewModel = AnalyticsViewModel()
    let theme = ThemeManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if viewModel.sessions.isEmpty && !viewModel.isLoading {
                        emptyState
                    } else {
                        thresholdChart
                        reactionTimeChart
                    }
                }
                .padding()
            }
            .background(theme.bg)
            .navigationTitle(String(localized: "analytics_title"))
            .navigationBarTitleDisplayMode(.large)
        }
        .task { await viewModel.load() }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundStyle(theme.textMuted)

            Text(String(localized: "analytics_empty"))
                .font(.headline)
                .foregroundStyle(theme.textSub)

            Text(String(localized: "analytics_empty_detail"))
                .font(.subheadline)
                .foregroundStyle(theme.textMuted)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }

    // MARK: - Threshold Chart

    private var thresholdChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "analytics_threshold_trend"))
                .font(.headline)
                .foregroundStyle(theme.text)

            if !viewModel.thresholdPoints.isEmpty {
                Chart(viewModel.thresholdPoints) { point in
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
                            colors: [theme.accent.opacity(0.3), theme.accent.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Threshold", point.threshold)
                    )
                    .foregroundStyle(theme.accent)
                    .symbolSize(30)
                }
                .chartYScale(domain: .automatic(includesZero: false))
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            Text("\(value.as(Int.self) ?? 0)ms")
                                .font(.caption2)
                                .foregroundStyle(theme.textSub)
                        }
                    }
                }
                .frame(height: 220)
            }
        }
        .padding()
        .background(theme.bgCard, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: theme.cardShadow, radius: 6, y: 3)
    }

    // MARK: - Reaction Time Chart

    private var reactionTimeChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "analytics_reaction_time"))
                .font(.headline)
                .foregroundStyle(theme.text)

            if !viewModel.reactionTimePoints.isEmpty {
                Chart(viewModel.reactionTimePoints) { point in
                    PointMark(
                        x: .value("Trial", point.trialNumber),
                        y: .value("RT", point.reactionTime)
                    )
                    .foregroundStyle(point.isCorrect ? theme.teal : Color(hex: "FF453A"))
                    .symbolSize(40)
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            Text("\(value.as(Int.self) ?? 0)ms")
                                .font(.caption2)
                                .foregroundStyle(theme.textSub)
                        }
                    }
                }
                .frame(height: 200)
            } else {
                Text(String(localized: "analytics_no_rt_data"))
                    .font(.subheadline)
                    .foregroundStyle(theme.textMuted)
            }
        }
        .padding()
        .background(theme.bgCard, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: theme.cardShadow, radius: 6, y: 3)
    }
}
