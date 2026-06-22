//
//  KeychainSessionStore.swift
//  costa
//

import Foundation
import Security

struct StoredTokens {
    let access: String
    let refresh: String?
    let expiresAt: Int64?
}

enum KeychainSessionStore {
    private static let service = "com.abui.costa.auth"
    private static let accessAccount = "access_token"
    private static let refreshAccount = "refresh_token"
    private static let expiresAtAccount = "expires_at"

    static func loadTokens() -> StoredTokens? {
        guard let access = loadString(account: accessAccount) else { return nil }
        let refresh = loadString(account: refreshAccount)
        let expiresAtStr = loadString(account: expiresAtAccount)
        let expiresAt = expiresAtStr.flatMap { Int64($0) }
        return StoredTokens(access: access, refresh: refresh, expiresAt: expiresAt)
    }

    static func save(session: AuthSession) throws {
        try saveString(session.access_token, account: accessAccount)
        if let refresh = session.refresh_token {
            try saveString(refresh, account: refreshAccount)
        } else {
            try? delete(account: refreshAccount)
        }

        let expiresAt: Int64
        if let storedExpiresAt = session.expires_at {
            expiresAt = storedExpiresAt
        } else if let expiresIn = session.expires_in {
            expiresAt = Int64(Date().timeIntervalSince1970) + Int64(expiresIn)
        } else {
            expiresAt = Int64(Date().timeIntervalSince1970) + 3600
        }
        try saveString(String(expiresAt), account: expiresAtAccount)
    }

    static func clear() throws {
        try delete(account: accessAccount)
        try delete(account: refreshAccount)
        try delete(account: expiresAtAccount)
    }

    private static func loadString(account: String) -> String? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func saveString(_ value: String, account: String) throws {
        let data = Data(value.utf8)
        try delete(account: account)
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.status(status)
        }
    }

    private static func delete(account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }

    enum KeychainError: Error {
        case status(OSStatus)
    }
}
