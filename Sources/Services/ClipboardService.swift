import AppKit

/// Clipboard management with auto-clear for security.
final class ClipboardService {
    static let shared = ClipboardService()
    private let pb = NSPasteboard.general
    private var clearTimer: Timer?

    /// Copy text and schedule auto-clear.
    func copy(_ text: String, clearAfter seconds: TimeInterval = 45) {
        pb.clearContents()
        pb.setString(text, forType: .string)
        scheduleClear(after: seconds)
    }

    private func scheduleClear(after seconds: TimeInterval) {
        clearTimer?.invalidate()
        clearTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { [weak self] _ in
            guard let self, self.pb.string(forType: .string) != nil else { return }
            self.pb.clearContents()
        }
    }
}
