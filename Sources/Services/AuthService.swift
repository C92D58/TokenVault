import LocalAuthentication

/// Face ID / Touch ID / device password authentication.
final class AuthService: ObservableObject {
    @Published var isLocked = true
    @Published var authFailed = false

    private let context = LAContext()

    /// Check if biometrics are available.
    var biometryType: String {
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return "none"
        }
        switch context.biometryType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        default: return "密碼"
        }
    }

    /// Authenticate the user.
    func authenticate(reason: String = "解鎖 TokenVault 以存取你的 API 密鑰") async -> Bool {
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) else {
            await MainActor.run { isLocked = false } // Fallback: no auth available
            return true
        }
        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
            await MainActor.run {
                isLocked = !success
                authFailed = !success
            }
            return success
        } catch {
            await MainActor.run { authFailed = true }
            return false
        }
    }

    /// Lock the app.
    func lock() {
        isLocked = true
        authFailed = false
    }

    /// Call when app goes to background.
    func autoLock() {
        isLocked = true
    }
}
