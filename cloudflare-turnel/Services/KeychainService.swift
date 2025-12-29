//
//  KeychainService.swift
//  iturnel
//

import Foundation
import Security

struct KeychainService {
    static func saveToken(_ token: String, for account: String = "default") throws {
        let data = Data(token.utf8)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.keychainService,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]

        // Delete any existing item
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.unableToSave(status)
        }
    }

    static func getToken(for account: String = "default") -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.keychainService,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    static func deleteToken(for account: String = "default") {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.keychainService,
            kSecAttrAccount as String: account
        ]

        SecItemDelete(query as CFDictionary)
    }

    static func getAllAccounts() -> [String] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.keychainService,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let items = result as? [[String: Any]] else {
            return []
        }

        return items.compactMap { $0[kSecAttrAccount as String] as? String }
    }
}

enum KeychainError: LocalizedError {
    case unableToSave(OSStatus)
    case unableToRead(OSStatus)

    var errorDescription: String? {
        switch self {
        case .unableToSave(let status):
            return "Unable to save to Keychain: \(status)"
        case .unableToRead(let status):
            return "Unable to read from Keychain: \(status)"
        }
    }
}
