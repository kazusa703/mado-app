import SwiftUI

enum AppTheme: String, CaseIterable {
    case system
    case light
    case dark

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    var displayName: String {
        switch self {
        case .system: String(localized: "theme_system")
        case .light: String(localized: "theme_light")
        case .dark: String(localized: "theme_dark")
        }
    }
}

@Observable
final class ThemeManager {
    static let shared = ThemeManager()

    var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "appTheme")
        }
    }

    var isDark: Bool {
        switch currentTheme {
        case .dark: true
        case .light: false
        case .system: _systemIsDark
        }
    }

    private var _systemIsDark = false

    private init() {
        let stored = UserDefaults.standard.string(forKey: "appTheme") ?? "system"
        self.currentTheme = AppTheme(rawValue: stored) ?? .system
    }

    func updateSystemScheme(_ scheme: ColorScheme) {
        _systemIsDark = (scheme == .dark)
    }

    // MARK: - Resolved colors

    var bg: Color { isDark ? ThemeColors.Dark.bg : ThemeColors.Light.bg }
    var bgCard: Color { isDark ? ThemeColors.Dark.bgCard : ThemeColors.Light.bgCard }
    var bgSurface: Color { isDark ? ThemeColors.Dark.bgSurface : ThemeColors.Light.bgSurface }
    var bgGrouped: Color { isDark ? ThemeColors.Dark.bgGrouped : ThemeColors.Light.bgGrouped }
    var accent: Color { isDark ? ThemeColors.Dark.accent : ThemeColors.Light.accent }
    var accentSoft: Color { isDark ? ThemeColors.Dark.accentSoft : ThemeColors.Light.accentSoft }
    var accentDark: Color { isDark ? ThemeColors.Dark.accentDark : ThemeColors.Light.accentDark }
    var teal: Color { isDark ? ThemeColors.Dark.teal : ThemeColors.Light.teal }
    var tealSoft: Color { isDark ? ThemeColors.Dark.tealSoft : ThemeColors.Light.tealSoft }
    var gold: Color { isDark ? ThemeColors.Dark.gold : ThemeColors.Light.gold }
    var goldSoft: Color { isDark ? ThemeColors.Dark.goldSoft : ThemeColors.Light.goldSoft }
    var text: Color { isDark ? ThemeColors.Dark.text : ThemeColors.Light.text }
    var textSub: Color { isDark ? ThemeColors.Dark.textSub : ThemeColors.Light.textSub }
    var textMuted: Color { isDark ? ThemeColors.Dark.textMuted : ThemeColors.Light.textMuted }
    var border: Color { isDark ? ThemeColors.Dark.border : ThemeColors.Light.border }
    var cardShadow: Color { isDark ? ThemeColors.Dark.cardShadow : ThemeColors.Light.cardShadow }
    var windowInner: Color { isDark ? ThemeColors.Dark.windowInner : ThemeColors.Light.windowInner }
    var windowFrame: Color { isDark ? ThemeColors.Dark.windowFrame : ThemeColors.Light.windowFrame }
    var windowFrost: Color { isDark ? ThemeColors.Dark.windowFrost : ThemeColors.Light.windowFrost }
}
