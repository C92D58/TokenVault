import Foundation

/// Localizes a Chinese source string at runtime.
///
/// SwiftUI localizes `Text("…")` automatically, but our own helper views take `String` labels and
/// several models expose display text as `String`. Those bypass the automatic lookup, so they go
/// through here instead. A key with no translation (user data, provider names) comes back
/// unchanged, which makes it safe to call on anything.
func L(_ key: String) -> String {
    String(localized: String.LocalizationValue(key))
}

/// Same, for a key plus arguments (`%lld`, `%@`).
func L(_ key: String, _ arguments: CVarArg...) -> String {
    String(format: L(key), arguments: arguments)
}
