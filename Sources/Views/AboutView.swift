import SwiftUI

struct AboutView: View {
    @State private var tapped = 0

    var body: some View {
        VStack(spacing: 24) {
            // App icon — glass card
            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color(.controlBackgroundColor))
                    .frame(width: 84, height: 84)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.10), radius: 14, y: 5)
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(DS.Color.accentGradient)
            }

            VStack(spacing: 4) {
                Text("TokenVault")
                    .font(.system(size: 22, weight: .bold))
                    .tracking(-0.5)
                Text("版本 \(appVersion)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 6) {
                Text("API Token 管理器")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                HStack(spacing: 6) {
                    badge("AES-256", icon: "lock.fill", color: .green)
                    badge("iCloud", icon: "icloud.fill", color: .blue)
                    badge("Face ID", icon: "faceid", color: .orange)
                }
            }

            // Open source badge
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left.forwardslash.chevron.right").font(.system(size: 10))
                    Text("開源 · MIT").font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(DS.Color.accent)
                .padding(.horizontal, 14).padding(.vertical, 6)
                .background(Capsule().fill(DS.Color.accent.opacity(0.1)))
                .overlay(Capsule().stroke(DS.Color.accent.opacity(0.2), lineWidth: 1))
            }

            Divider().frame(width: 200)

            // Brand credit — TECXIA | DIGITAL STUDIO (the mark is drawn, not typeset).
            HStack(spacing: 7) {
                TCrossMark()
                    .frame(width: 10, height: 10)
                Text("TECXIA")
                Rectangle()
                    .fill(Color.secondary.opacity(0.45))
                    .frame(width: 1, height: 10)
                Text("DIGITAL STUDIO")
            }
            .font(.system(size: 11, weight: .medium))
            .tracking(1.4)
            .foregroundColor(.secondary)

        }
        .padding(30)
        .frame(width: 380, height: 420)
        .background(
            ZStack {
                Color(.controlBackgroundColor)
                DS.Color.accentGradientSubtle.opacity(0.5)
            }
        )
        .background(.ultraThinMaterial)
        .onTapGesture { tapped += 1 }
        .overlay(alignment: .bottom) {
            if tapped >= 5 {
                Text("🔐 安全無小事")
                    .font(.system(size: 10))
                    .foregroundStyle(DS.Color.accentGradient)
                    .padding(.bottom, 10)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: tapped)
    }

    private var appVersion: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0"
    }

    private func badge(_ text: String, icon: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon).font(.system(size: 9))
            Text(text).font(.system(size: 10, weight: .medium))
        }
        .foregroundColor(color)
        .padding(.horizontal, 7).padding(.vertical, 3)
        .background(Capsule().fill(color.opacity(0.1)))
    }
}


/// The TECXIA credit mark: the cross is not a letter — it is two Ts crossed,
/// each diagonal stroke ending in its own bar (a cross potent, turned on its
/// diagonal). Drawn, not typeset, so it is the same in every language.
private struct TCrossMark: View {
    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let lineWidth = w * 0.14
            let inset = w * 0.09
            let cap = w * 0.36
            let style = StrokeStyle(lineWidth: lineWidth, lineCap: .butt)
            var cross = Path()
            cross.move(to: CGPoint(x: inset, y: inset))
            cross.addLine(to: CGPoint(x: w - inset, y: h - inset))
            cross.move(to: CGPoint(x: w - inset, y: inset))
            cross.addLine(to: CGPoint(x: inset, y: h - inset))
            context.stroke(cross, with: .foreground, style: style)
            let arms: [(CGPoint, CGPoint)] = [
                (CGPoint(x: inset, y: inset), CGPoint(x: w - inset, y: h - inset)),
                (CGPoint(x: w - inset, y: h - inset), CGPoint(x: inset, y: inset)),
                (CGPoint(x: w - inset, y: inset), CGPoint(x: inset, y: h - inset)),
                (CGPoint(x: inset, y: h - inset), CGPoint(x: w - inset, y: inset)),
            ]
            for (tip, other) in arms {
                let dx = tip.x - other.x, dy = tip.y - other.y
                let length = max(1, (dx * dx + dy * dy).squareRoot())
                let px = -dy / length, py = dx / length
                var bar = Path()
                bar.move(to: CGPoint(x: tip.x - px * cap / 2, y: tip.y - py * cap / 2))
                bar.addLine(to: CGPoint(x: tip.x + px * cap / 2, y: tip.y + py * cap / 2))
                context.stroke(bar, with: .foreground, style: style)
            }
        }
    }
}
