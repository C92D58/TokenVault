import Foundation
import Security

/// Keychain-backed storage for the master AES key.
///
/// iOS has no `kSecAttrKeyTypeAES` item class, so the same 32 bytes are stored there as a generic
/// password keyed by application tag. macOS keeps its original key-class items, so keys created by
/// earlier builds are still found.
enum KeychainService {
    private static let account = "org.wahsun.tokenvault.masterkey"

    #if os(iOS)
    private static func baseQuery(tag: Data) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: tag,
            kSecAttrAccount as String: account,
        ]
    }
    #else
    private static func baseQuery(tag: Data) -> [String: Any] {
        [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: tag,
            kSecAttrKeyType as String: kSecAttrKeyTypeAES,
        ]
    }
    #endif

    private static func query(tag: Data) -> [String: Any] {
        var query = baseQuery(tag: tag)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        return query
    }

    /// Store raw AES key data in Keychain.
    static func write(tag: Data, data: Data) throws {
        // Delete existing
        SecItemDelete(baseQuery(tag: tag) as CFDictionary)

        var addQuery = baseQuery(tag: tag)
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unexpected(status)
        }
    }

    /// Read raw AES key data from Keychain.
    static func read(tag: Data) throws -> Data {
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query(tag: tag) as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else {
            throw KeychainError.unexpected(status)
        }
        return data
    }

    /// Delete key from Keychain.
    static func delete(tag: Data) throws {
        let status = SecItemDelete(query(tag: tag) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpected(status)
        }
    }
}

enum KeychainError: Error {
    case unexpected(OSStatus)
}
