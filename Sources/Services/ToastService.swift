import SwiftUI

/// Non-intrusive toast notification overlay with glass styling.
final class ToastService: ObservableObject {
    static let shared = ToastService()

    @Published var message = ""
    @Published var icon = "checkmark.circle"
    @Published var isVisible = false

    private var hideWork: DispatchWorkItem?

    func show(_ msg: String, icon: String = "checkmark.circle", duration: TimeInterval = 2.0) {
        hideWork?.cancel()
        message = msg; self.icon = icon
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { isVisible = true }
        let work = DispatchWorkItem { [weak self] in
            withAnimation(.easeOut(duration: 0.25)) { self?.isVisible = false }
        }
        hideWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: work)
    }
}

struct ToastOverlay: View {
    @ObservedObject var toast = ToastService.shared

    var body: some View {
        VStack {
            Spacer()
            if toast.isVisible {
                HStack(spacing: 8) {
                    Image(systemName: toast.icon)
                        .font(.system(size: 13, weight: .semibold))
                    Text(toast.message)
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 18).padding(.vertical, 11)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.75))
                )
                .overlay(
                    Capsule()
                        .stroke(.white.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.2), radius: 16, y: 6)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding(.bottom, 28)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: toast.isVisible)
        .allowsHitTesting(false)
    }
}
