// ============================================================================
// SecureStorage.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: Store Layer
// Purpose: Keychain wrapper for storing OAuth tokens securely. Uses the
//          Security framework directly (no third-party dependencies).
//          Tokens are stored per-service (e.g., "com.sanctuarysound.pco").
// ============================================================================

import Foundation
import Security


// MARK: - ─── PCO Tokens ──────────────────────────────────────────────────

struct PCOTokens: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    let scope: String
}


// MARK: - ─── Secure Storage ──────────────────────────────────────────────

enum SecureStorage {

    private static let service = "com.sanctuarysound"

    // ── Save ──

    static func saveTokens(_ tokens: PCOTokens, account: String = "pco") throws {
        let data = try JSONEncoder().encode(tokens)

        // Delete existing first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Add new
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw SecureStorageError.saveFailed(status)
        }
    }

    // ── Load ──

    static func loadTokens(account: String = "pco") -> PCOTokens? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let tokens = try? JSONDecoder().decode(PCOTokens.self, from: data) else {
            return nil
        }

        return tokens
    }

    // ── Delete ──

    static func clearTokens(account: String = "pco") {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
    }

    // ── Check ──

    static func hasTokens(account: String = "pco") -> Bool {
        loadTokens(account: account) != nil
    }
}


// MARK: - ─── Errors ──────────────────────────────────────────────────────

enum SecureStorageError: LocalizedError {
    case saveFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "Keychain save failed (OSStatus: \(status))"
        }
    }
}
