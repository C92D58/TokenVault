import AppKit

final class ClipboardService {
    static let shared = ClipboardService()
    private let pasteboard = NSPasteboard.general
    private var previousContent: String?

    func copy(_ text: String) {
        previousContent = pasteboard.string(forType: .string)
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    /// Restore previous clipboard content after a delay
    func restoreAfter(seconds: TimeInterval = 30) {
        guard let previous = previousContent else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { [weak self] in
            self?.pasteboard.clearContents()
            self?.pasteboard.setString(previous, forType: .string)
        }
    }
}
