import SwiftUI

// MARK: - Visual Effects System
// SwiftUI-native equivalents of popular JS/web effects:
// shimmer, ripple, particles, glow, animated gradients.

// MARK: - 1. Shimmer / Skeleton Loading Effect

/// Shimmer effect — animated gradient sweep for loading states.
struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = -1.0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.0),
                                    Color.white.opacity(0.15),
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.15),
                                    Color.white.opacity(0.0),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .rotationEffect(.degrees(70))
                        .offset(x: phase * geo.size.width * 1.5)
                        .mask(content)
                }
            )
            .onAppear {
                withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                    phase = 1.0
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
}

// MARK: - 1.5 Skeleton Loading Row

/// Skeleton loading row with shimmer — for loading states.
/// Apple HIG: prefer skeleton over spinner.
struct SkeletonRow: View {
    let height: CGFloat

    init(height: CGFloat = 20) {
        self.height = height
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color.primary.opacity(0.06))
            .frame(height: height)
            .shimmer()
    }
}

// MARK: - 2. Ripple / Click Feedback Effect

/// Ripple effect that expands from a point — used for copy feedback.
struct RippleEffect: ViewModifier {
    @State private var ripples: [(id: UUID, scale: CGFloat, opacity: Double)] = []
    let color: Color

    func body(content: Content) -> some View {
        content
            .overlay(
                ForEach(ripples, id: \.id) { ripple in
                    Circle()
                        .stroke(color, lineWidth: 1.5)
                        .scaleEffect(ripple.scale)
                        .opacity(ripple.opacity)
                        .animation(.easeOut(duration: 0.6), value: ripple.scale)
                }
            )
            .onAppear {
                trigger()
            }
    }

    func trigger() {
        let id = UUID()
        ripples.append((id: id, scale: 0.3, opacity: 0.8))
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
            if let idx = ripples.firstIndex(where: { $0.id == id }) {
                ripples[idx].scale = 3.0
                ripples[idx].opacity = 0.0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            ripples.removeAll { $0.id == id }
        }
    }
}

// MARK: - 3. Animated Gradient Flow

/// Continuously animating gradient — for brand elements and accents.
struct AnimatedGradient: View {
    let colors: [Color]
    @State private var start = UnitPoint(x: 0, y: 0)
    @State private var end = UnitPoint(x: 1, y: 1)

    var body: some View {
        LinearGradient(colors: colors, startPoint: start, endPoint: end)
            .onAppear {
                withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                    start = UnitPoint(x: 1, y: 0.2)
                    end = UnitPoint(x: 0, y: 0.8)
                }
            }
    }
}

// MARK: - 4. Ambient Floating Particles

/// Floating particles for lock screen / background ambiance.
struct ParticleField: View {
    let count: Int
    let color: Color
    @State private var tick = 0.0

    private struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var speed: Double
        var opacity: Double
        var delay: Double
    }

    private let particles: [Particle] = {
        (0..<20).map { _ in
            Particle(
                x: CGFloat.random(in: 0...1),
                y: CGFloat.random(in: 0...1),
                size: CGFloat.random(in: 2...6),
                speed: Double.random(in: 8...20),
                opacity: Double.random(in: 0.1...0.35),
                delay: Double.random(in: 0...5)
            )
        }
    }()

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                for p in particles {
                    let y = (p.y + CGFloat((t + p.delay).truncatingRemainder(dividingBy: p.speed) / p.speed))
                        .truncatingRemainder(dividingBy: 1.3) - 0.15
                    let rect = CGRect(
                        x: p.x * size.width,
                        y: y * size.height,
                        width: p.size,
                        height: p.size
                    )
                    ctx.fill(
                        Circle().path(in: rect),
                        with: .color(color.opacity(p.opacity))
                    )
                    // Soft glow
                    ctx.addFilter(.blur(radius: 2))
                    ctx.fill(
                        Circle().path(in: rect.insetBy(dx: -1, dy: -1)),
                        with: .color(color.opacity(p.opacity * 0.5))
                    )
                }
            }
        }
    }
}

// MARK: - 5. Glass Edge Glow

/// Animated glow along the edge of a glass surface — triggered on interaction.
struct GlassEdgeGlow: ViewModifier {
    let isActive: Bool
    let gradient: LinearGradient
    @State private var glowPhase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(
                        AngularGradient(
                            colors: [
                                .white.opacity(0.0),
                                .white.opacity(isActive ? 0.15 : 0.0),
                                DS.Color.accent.opacity(isActive ? 0.20 : 0.0),
                                .white.opacity(isActive ? 0.15 : 0.0),
                                .white.opacity(0.0),
                            ],
                            center: .center,
                            angle: .degrees(glowPhase)
                        ),
                        lineWidth: 1.5
                    )
                    .blur(radius: isActive ? 2 : 0)
            )
            .onChange(of: isActive) { _, active in
                if active {
                    withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                        glowPhase = 360
                    }
                } else {
                    glowPhase = 0
                }
            }
    }
}

extension View {
    func glassEdgeGlow(isActive: Bool) -> some View {
        modifier(GlassEdgeGlow(isActive: isActive, gradient: DS.Color.accentGradient))
    }
}

// MARK: - 6. Copy Flash Overlay

/// Bright flash + checkmark overlay when a token is copied.
struct CopyFlash: ViewModifier {
    let trigger: Bool
    @State private var flashScale: CGFloat = 1.0
    @State private var flashOpacity: Double = 0.3
    @State private var checkScale: CGFloat = 0.5
    @State private var checkOpacity: Double = 0

    func body(content: Content) -> some View {
        content
            .overlay {
                if flashOpacity > 0 {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.white.opacity(flashOpacity))
                        .scaleEffect(flashScale)
                }
            }
            .overlay {
                if checkOpacity > 0 {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.green)
                        .scaleEffect(checkScale)
                        .opacity(checkOpacity)
                }
            }
            .onChange(of: trigger) { _, new in
                if new {
                    withAnimation(.easeOut(duration: 0.15)) { flashOpacity = 0.3; flashScale = 1 }
                    withAnimation(.easeOut(duration: 0.4).delay(0.1)) { flashOpacity = 0 }
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.5).delay(0.05)) {
                        checkScale = 1.2; checkOpacity = 1
                    }
                    withAnimation(.easeOut(duration: 0.3).delay(0.8)) {
                        checkScale = 0.5; checkOpacity = 0
                    }
                }
            }
    }
}

// MARK: - 7. SF Symbol Copy Feedback

/// Lightweight copy feedback using SF Symbol animation (.bounce).
/// Use for button-level icons where the full CopyFlash overlay is overkill.
struct SymbolCopyFeedback: ViewModifier {
    let trigger: Bool
    @State private var bounce = false

    func body(content: Content) -> some View {
        content
            .symbolEffect(.bounce, value: bounce)
            .onChange(of: trigger) { _, new in
                if new { bounce = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { bounce = false }
            }
    }
}

extension View {
    func rippleClick(color: Color = DS.Color.accent) -> some View {
        modifier(RippleEffect(color: color))
    }

    func copyFlash(trigger: Bool) -> some View {
        modifier(CopyFlash(trigger: trigger))
    }

    /// SF Symbol bounce effect for copy confirmations.
    func symbolBounce(trigger: Bool) -> some View {
        modifier(SymbolCopyFeedback(trigger: trigger))
    }
}
