import Foundation
import Security

/// Secure Enclave-backed Keychain operations.
enum KeychainService {
    private static func query(tag: Data) -> [String: Any] {
        [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: tag,
            kSecAttrKeyType as String: kSecAttrKeyTypeAES,
            kSecReturnData as String: true,
        ]
    }

    /// Store raw AES key data in Keychain.
    static func write(tag: Data, data: Data) throws {
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: tag,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]
        // Delete existing
        SecItemDelete(addQuery as CFDictionary)
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
