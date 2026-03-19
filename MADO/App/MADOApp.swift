import SwiftUI

@main
struct MADOApp: App {
    @Environment(\.colorScheme) private var systemScheme

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onChange(of: systemScheme) { _, newScheme in
                    ThemeManager.shared.updateSystemScheme(newScheme)
                }
                .onAppear {
                    ThemeManager.shared.updateSystemScheme(systemScheme)
                }
                .preferredColorScheme(ThemeManager.shared.currentTheme.colorScheme)
        }
    }
}
