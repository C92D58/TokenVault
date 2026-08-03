import AppKit

/// Clipboard management with auto-clear for security.
/// Only clears the clipboard if the content hasn't been replaced by the user.
final class ClipboardService {
    static let shared = ClipboardService()
    private let pb = NSPasteboard.general
    private var clearTimer: Timer?
    private var originalChangeCount: Int = 0

    /// Copy text and schedule auto-clear. Set clearAfter to 0 to never clear.
    func copy(_ text: String, clearAfter seconds: TimeInterval = 45) {
        pb.clearContents()
        pb.setString(text, forType: .string)
        originalChangeCount = pb.changeCount
        guard seconds > 0 else { return } // 0 = never clear
        scheduleClear(after: seconds)
    }

    private func scheduleClear(after seconds: TimeInterval) {
        clearTimer?.invalidate()
        clearTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { [weak self] _ in
            guard let self else { return }
            // Only clear if the clipboard hasn't been modified since our copy
            guard self.pb.changeCount == self.originalChangeCount else { return }
            self.pb.clearContents()
        }
    }
}
