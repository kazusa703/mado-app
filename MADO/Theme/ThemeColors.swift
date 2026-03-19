import SwiftUI

struct ThemeColors {
    struct Light {
        static let bg            = Color(hex: "FFFFFF")
        static let bgCard        = Color(hex: "FFFFFF")
        static let bgSurface     = Color(hex: "F5F5F7")
        static let bgGrouped     = Color(hex: "F2F2F7")

        static let accent        = Color(hex: "4A90B8")
        static let accentSoft    = Color(hex: "E4F0F8")
        static let accentDark    = Color(hex: "2E6B8E")

        static let teal          = Color(hex: "34C759")
        static let tealSoft      = Color(hex: "E4F5EB")
        static let gold          = Color(hex: "D4A853")
        static let goldSoft      = Color(hex: "FFF8E8")

        static let text          = Color(hex: "1C1C1E")
        static let textSub       = Color(hex: "6E6E73")
        static let textMuted     = Color(hex: "AEAEB2")

        static let border        = Color(hex: "E5E5EA")
        static let cardShadow    = Color.black.opacity(0.06)

        static let tabBarBg      = Color(hex: "FFFFFF").opacity(0.92)

        static let windowInner   = Color(hex: "4A90B8")
        static let windowFrame   = Color(hex: "D1D5DB")
        static let windowFrost   = Color(hex: "E0E7EF").opacity(0.7)
    }

    struct Dark {
        static let bg            = Color(hex: "0B0E18")
        static let bgCard        = Color(hex: "131829")
        static let bgSurface     = Color(hex: "1A2035")
        static let bgGrouped     = Color(hex: "101420")

        static let accent        = Color(hex: "4CA6E8")
        static let accentSoft    = Color(hex: "4CA6E8").opacity(0.12)
        static let accentDark    = Color(hex: "6CBAF0")

        static let teal          = Color(hex: "34D4B0")
        static let tealSoft      = Color(hex: "34D4B0").opacity(0.12)
        static let gold          = Color(hex: "E8C84C")
        static let goldSoft      = Color(hex: "E8C84C").opacity(0.12)

        static let text          = Color(hex: "E8ECF4")
        static let textSub       = Color(hex: "8892A8")
        static let textMuted     = Color(hex: "4A5268")

        static let border        = Color(hex: "1E2640")
        static let cardShadow    = Color.clear

        static let tabBarBg      = Color(hex: "0B0E18").opacity(0.94)

        static let windowInner   = Color(hex: "4CA6E8")
        static let windowFrame   = Color(hex: "1E2640")
        static let windowFrost   = Color(hex: "0B0E18").opacity(0.9)
    }

    struct Session {
        static let bg            = Color(hex: "06080E")
        static let surface       = Color(hex: "0D1020")
        static let border        = Color(hex: "1A1E2E")
        static let text          = Color.white.opacity(0.85)
        static let textMuted     = Color.white.opacity(0.35)
        static let fixation      = Color(hex: "4CA6E8").opacity(0.6)
        static let maskBlock     = Color.white.opacity(0.15)
    }
}
