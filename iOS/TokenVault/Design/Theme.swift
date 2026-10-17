import SwiftUI
import UIKit

/// One palette, resolved per appearance.
///
/// Violet is the brand: the accent marks what is selected, what is live, what was just copied.
/// Everything else is ink on a layered neutral — a warm off-white by day, near-black at night —
/// so a screens-worth of secrets still reads quietly.
enum Theme {

    // MARK: - Accent

    static let accent = Color(red: 0.60, green: 0.47, blue: 0.98)          // #9A78FA
    static let accentDeep = Color(red: 0.44, green: 0.32, blue: 0.87)
    static let accentSoft = Color(red: 0.60, green: 0.47, blue: 0.98, opacity: 0.14)

    static let accentGradient = LinearGradient(
        colors: [Color(red: 0.70, green: 0.58, blue: 1.00), Color(red: 0.42, green: 0.30, blue: 0.88)],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    // MARK: - Surfaces

    static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? dark : light })
    }

    static let background = adaptive(light: UIColor(white: 0.965, alpha: 1),
                                     dark: UIColor(white: 0.035, alpha: 1))
    static let backgroundGlow = adaptive(light: UIColor(red: 0.90, green: 0.88, blue: 1.0, alpha: 1),
                                         dark: UIColor(red: 0.10, green: 0.08, blue: 0.20, alpha: 1))
    /// Cards and list rows.
    static let surface = adaptive(light: .white,
                                  dark: UIColor(white: 0.085, alpha: 1))
    /// A step above a card: value panels, insets, selected chips.
    static let surfaceRaised = adaptive(light: UIColor(white: 0.945, alpha: 1),
                                        dark: UIColor(white: 0.125, alpha: 1))
    static let surfaceDeep = adaptive(light: UIColor(white: 0.915, alpha: 1),
                                      dark: UIColor(white: 0.06, alpha: 1))

    // MARK: - Lines

    static let hairline = adaptive(light: UIColor(white: 0, alpha: 0.09),
                                   dark: UIColor(white: 1, alpha: 0.13))
    static let hairlineStrong = adaptive(light: UIColor(white: 0, alpha: 0.16),
                                         dark: UIColor(white: 1, alpha: 0.24))

    // MARK: - Ink
    // Light needs more ink than dark needs white: a grey that reads on black vanishes on paper.

    static let textPrimary = adaptive(light: UIColor(white: 0.08, alpha: 1),
                                      dark: UIColor(white: 1, alpha: 0.96))
    static let textSecondary = adaptive(light: UIColor(white: 0.08, alpha: 0.72),
                                        dark: UIColor(white: 1, alpha: 0.70))
    static let textTertiary = adaptive(light: UIColor(white: 0.08, alpha: 0.56),
                                       dark: UIColor(white: 1, alpha: 0.54))

    // MARK: - Semantics

    static let success = Color(red: 0.13, green: 0.70, blue: 0.42)
    static let warning = Color(red: 0.94, green: 0.62, blue: 0.06)
    static let danger = Color(red: 0.92, green: 0.29, blue: 0.29)

    // MARK: - Type

    static let title = Font.system(size: 30, weight: .bold)
    static let heading = Font.system(size: 19, weight: .semibold)
    static let cardTitle = Font.system(size: 16, weight: .semibold)
    static let body = Font.system(size: 15, weight: .regular)
    static let callout = Font.system(size: 13, weight: .regular)
    static let label = Font.system(size: 12, weight: .medium)
    static let caption = Font.system(size: 11, weight: .regular)
    static let mono = Font.system(size: 13, weight: .regular, design: .monospaced)
    static let monoSmall = Font.system(size: 11, weight: .regular, design: .monospaced)

    // MARK: - Geometry

    enum Radius {
        /// Rows and tiles.
        static let card: CGFloat = 16
        /// Sheets, hero panels.
        static let panel: CGFloat = 24
        /// Controls whose shape identifies them.
        static let control: CGFloat = 12
        static let chip: CGFloat = 999
    }

    enum Space {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 6
        static let s: CGFloat = 10
        static let m: CGFloat = 14
        static let l: CGFloat = 18
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 34
    }

    /// Screen-edge inset shared by headers, cards and footers.
    static let inset: CGFloat = 18

    // MARK: - Motion

    enum Motion {
        static let press = Animation.easeOut(duration: 0.16)
        static let snap = Animation.spring(response: 0.28, dampingFraction: 0.82)
        static let appear = Animation.spring(response: 0.42, dampingFraction: 0.86)
    }
}

// MARK: - Hex

extension Color {
    /// `Color(hex: "#9A78FA")` — also accepts a bare `9A78FA`.
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "# "))
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let r = Double((value & 0xFF0000) >> 16) / 255
        let g = Double((value & 0x00FF00) >> 8) / 255
        let b = Double(value & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
