import Foundation
import UIKit

/// Clipboard with an expiry.
///
/// The auto-clear only fires when the pasteboard still holds what we put there — if the user
/// copied something else in the meantime their clipboard is none of our business.
final class ClipboardService {
    static let shared = ClipboardService()

    private var deadline: Date?
    private var expectedChangeCount: Int?
    private var timer: Timer?

    func copy(_ text: String, clearAfter seconds: Int) {
        UIPasteboard.general.string = text
        expectedChangeCount = UIPasteboard.general.changeCount
        timer?.invalidate()
        timer = nil

        guard seconds > 0 else {
            deadline = nil
            return
        }
        deadline = Date().addingTimeInterval(TimeInterval(seconds))
        let work = Timer(timeInterval: TimeInterval(seconds), repeats: false) { [weak self] _ in
            self?.clearIfExpired()
        }
        RunLoop.main.add(work, forMode: .common)
        timer = work
    }

    func clearIfExpired() {
        guard let deadline, Date() >= deadline else { return }
        clearNow()
    }

    func clearNow() {
        timer?.invalidate()
        timer = nil
        deadline = nil
        if let expected = expectedChangeCount, UIPasteboard.general.changeCount == expected {
            UIPasteboard.general.string = ""
        }
        expectedChangeCount = nil
    }

    var hasPendingClear: Bool { deadline != nil }
}
