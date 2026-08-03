import SwiftUI

// MARK: - Surface Modifiers
// Solid-surface modifiers replacing the previous glass-effect materials.
// Uses opaque system colors for a clean, distraction-free appearance.

/// Level of surface prominence
enum SurfaceLevel {
    case subtle     // Slightly recessed — for sidebar, toolbar
    case standard   // Standard surface — for cards, panels
    case prominent  // Elevated surface — for lock screen, prominent panels
    case chrome     // Window chrome — for title bars

    var backgroundColor: Color {
        switch self {
        case .subtle:    return Color(.controlBackgroundColor)
        case .standard:  return Color(.controlBackgroundColor)
        case .prominent: return Color(.windowBackgroundColor)
        case .chrome:    return Color(.windowBackgroundColor)
        }
    }

    var strokeColor: Color {
        switch self {
        case .subtle:    return Color.primary.opacity(0.06)
        case .standard:  return Color.primary.opacity(0.08)
        case .prominent: return Color.primary.opacity(0.10)
        case .chrome:    return Color.primary.opacity(0.04)
        }
    }
}

// MARK: - Surface Modifier

/// Applies a solid background with a subtle border.
struct Surface: ViewModifier {
    let level: SurfaceLevel
    let cornerRadius: CGFloat

    init(level: SurfaceLevel = .standard, cornerRadius: CGFloat = 12) {
        self.level = level
        self.cornerRadius = cornerRadius
    }

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(level.backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(level.strokeColor, lineWidth: 1)
            )
    }
}

// MARK: - Card Modifier

/// Solid card with shadow, hover scale effect, and focus glow.
struct CardSurface: ViewModifier {
    let isHovering: Bool
    let isFocused: Bool
    let cornerRadius: CGFloat

    init(isHovering: Bool = false, isFocused: Bool = false, cornerRadius: CGFloat = 12) {
        self.isHovering = isHovering
        self.isFocused = isFocused
        self.cornerRadius = cornerRadius
    }

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(.controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        isFocused
                            ? Color(red: 0.60, green: 0.47, blue: 0.98).opacity(0.35)
                            : Color.primary.opacity(isHovering ? 0.10 : 0.06),
                        lineWidth: isFocused ? 1.5 : 1
                    )
            )
            .shadow(
                color: .black.opacity(isHovering || isFocused ? 0.08 : 0.04),
                radius: isHovering || isFocused ? 16 : 8,
                y: isHovering || isFocused ? 6 : 2
            )
            .scaleEffect(isHovering ? 1.01 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovering)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isFocused)
    }
}

// MARK: - Input Field Modifier

/// Text field with solid container styling.
struct InputField: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.textBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.primary.opacity(0.10), lineWidth: 1)
            )
    }
}

// MARK: - Ambient Glow Modifier

/// Subtle colored glow behind an element — used for brand accents.
struct AmbientGlow: ViewModifier {
    let color: Color
    let radius: CGFloat

    init(color: Color = Color(red: 0.60, green: 0.47, blue: 0.98), radius: CGFloat = 40) {
        self.color = color
        self.radius = radius
    }

    func body(content: Content) -> some View {
        content
            .background(
                Circle()
                    .fill(color.opacity(0.06))
                    .frame(width: radius * 2, height: radius * 2)
                    .blur(radius: radius * 0.5)
            )
    }
}

// MARK: - View Extensions

extension View {

    /// Apply solid surface background.
    func surface(level: SurfaceLevel = .standard, cornerRadius: CGFloat = 12) -> some View {
        modifier(Surface(level: level, cornerRadius: cornerRadius))
    }

    /// Apply solid card with hover/focus states.
    func cardSurface(isHovering: Bool = false, isFocused: Bool = false, cornerRadius: CGFloat = 12) -> some View {
        modifier(CardSurface(isHovering: isHovering, isFocused: isFocused, cornerRadius: cornerRadius))
    }

    /// Apply solid input field styling.
    func inputField() -> some View {
        modifier(InputField())
    }

    /// Apply ambient glow background.
    func ambientGlow(color: Color = Color(red: 0.60, green: 0.47, blue: 0.98), radius: CGFloat = 40) -> some View {
        modifier(AmbientGlow(color: color, radius: radius))
    }
}
