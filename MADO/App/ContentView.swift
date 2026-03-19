import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    let theme = ThemeManager.shared

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label(String(localized: "tab_home"), systemImage: "house.fill")
                }
                .tag(0)

            AnalyticsView()
                .tabItem {
                    Label(String(localized: "tab_analytics"), systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Label(String(localized: "tab_settings"), systemImage: "gearshape.fill")
                }
                .tag(2)
        }
        .tint(theme.accent)
    }
}
