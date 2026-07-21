import AppKit

final class ClipboardService {
    static let shared = ClipboardService()
    private let pb = NSPasteboard.general

    func copy(_ text: String) {
        pb.clearContents()
        pb.setString(text, forType: .string)
    }
}
