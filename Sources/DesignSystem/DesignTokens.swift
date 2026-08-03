import SwiftUI

// MARK: - Design System Tokens
// Centralized design parameters for the macOS 26 glass redesign.
// All views reference these tokens instead of hardcoding values.
//
// NOTE: When building with macOS 26 SDK, swap DS.Material.glassMaterial
// to use `.glass` with @available(macOS 26, *).

enum DS {

    // MARK: - Brand Colors

    enum Color {
        /// Primary accent — soft purple
        static let accent = SwiftUI.Color(red: 0.60, green: 0.47, blue: 0.98)
        /// Light accent variant
        static let accentLight = SwiftUI.Color(red: 0.72, green: 0.62, blue: 0.99)
        /// Dark accent variant
        static let accentDark = SwiftUI.Color(red: 0.48, green: 0.35, blue: 0.85)

        /// Accent gradient used across the app
        static let accentGradient = LinearGradient(
            colors: [accentLight, accentDark],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )

        /// Subtle accent gradient for backgrounds
        static let accentGradientSubtle = LinearGradient(
            colors: [accentLight.opacity(0.3), accentDark.opacity(0.15)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    // MARK: - Materials
    // When macOS 26 SDK is available, replace glassMaterial with:
    //   if #available(macOS 26, *) { return .glass } else { return .ultraThinMaterial }

    enum Material {
        /// Primary glass surface — ultraThinMaterial for translucency.
        /// On macOS 26+ this should become `.glass`.
        static let glassMaterial: SwiftUI.Material = .ultraThinMaterial

        /// Elevated surface for cards and prominent panels
        static let elevated: SwiftUI.Material = .regularMaterial

        /// Base surface for backgrounds
        static let base: SwiftUI.Material = .ultraThinMaterial

        /// Subtle surface for secondary areas
        static let subtle: SwiftUI.Material = .ultraThinMaterial

        /// Thick glass for lock screen and modal surfaces
        static let thick: SwiftUI.Material = .regularMaterial

        /// Chrome-level translucency for title bars
        static let chrome: SwiftUI.Material = .ultraThinMaterial
    }

    // MARK: - Typography

    enum Typography {
        static let largeTitle: Font = .system(size: 26, weight: .bold, design: .default)
        static let title: Font = .system(size: 22, weight: .bold, design: .default)
        static let titleMedium: Font = .system(size: 16, weight: .semibold)
        static let headline: Font = .system(size: 14, weight: .semibold)
        static let body: Font = .system(size: 13, weight: .regular)
        static let bodyMedium: Font = .system(size: 13, weight: .medium)
        static let callout: Font = .system(size: 12, weight: .regular)
        static let caption: Font = .system(size: 11, weight: .regular)
        static let captionBold: Font = .system(size: 11, weight: .semibold)
        static let tiny: Font = .system(size: 9, weight: .regular)
        static let monospaced: Font = .system(size: 11, design: .monospaced)
        static let monospacedSmall: Font = .system(size: 10, design: .monospaced)
        static let monospacedTiny: Font = .system(size: 9, design: .monospaced)
    }

    // MARK: - Corner Radius

    enum Radius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let full: CGFloat = 999
    }

    // MARK: - Spacing

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    // MARK: - Shadows

    enum Shadow {
        /// Subtle card shadow
        static let card = (color: SwiftUI.Color.black.opacity(0.04), radius: CGFloat(8), y: CGFloat(2))
        /// Elevated card shadow (hover state)
        static let cardElevated = (color: SwiftUI.Color.black.opacity(0.08), radius: CGFloat(16), y: CGFloat(6))
        /// Popover / floating panel shadow
        static let floating = (color: SwiftUI.Color.black.opacity(0.12), radius: CGFloat(24), y: CGFloat(8))
        /// Window-level shadow (minimal)
        static let window = (color: SwiftUI.Color.black.opacity(0.02), radius: CGFloat(4), y: CGFloat(1))
    }

    // MARK: - Animation

    enum Animation {
        /// Standard spring for UI transitions
        static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.7)
        /// Snappy spring for hover / micro-interactions
        static let snappy = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.6)
        /// Bouncy spring for prominent transitions
        static let bouncy = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.5)
        /// Gentle ease for opacity fades
        static let fade = SwiftUI.Animation.easeOut(duration: 0.25)

        /// Standard transition: scale + opacity
        static let appear = AnyTransition.scale(scale: 0.95).combined(with: .opacity)
        /// Slide-up transition for toasts
        static let slideUp = AnyTransition.move(edge: .bottom).combined(with: .opacity)
    }

    // MARK: - Card

    enum Card {
        static let height: CGFloat = 56
        static let accentBarWidth: CGFloat = 3
        static let iconSize: CGFloat = 32
        static let cornerRadius: CGFloat = Radius.md
    }
}

