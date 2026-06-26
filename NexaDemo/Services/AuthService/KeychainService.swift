import Foundation
import Security

actor KeychainService {
    static let shared = KeychainService()

    private let tokenKey = "nexademo_jwt_token"
    private let refreshTokenKey = "nexademo_refresh_token"
    private let service = "com.nexa.NexaDemo"

    private func baseQuery(account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: service
        ]
    }

    private func saveValue(_ value: String, for account: String) {
        var query = baseQuery(account: account)
        query[kSecValueData as String] = value.data(using: .utf8)
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private func readValue(for account: String) -> String? {
        var query = baseQuery(account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    private func deleteValue(for account: String) {
        let query = baseQuery(account: account)
        SecItemDelete(query as CFDictionary)
    }

    func saveSession(token: String, refreshToken: String?) {
        saveValue(token, for: tokenKey)

        if let refreshToken, refreshToken.isEmpty == false {
            saveValue(refreshToken, for: refreshTokenKey)
        }
    }

    func saveToken(_ token: String) {
        saveValue(token, for: tokenKey)
    }

    func getToken() -> String? {
        readValue(for: tokenKey)
    }

    func getRefreshToken() -> String? {
        readValue(for: refreshTokenKey)
    }

    func hasSession() -> Bool {
        getToken() != nil || getRefreshToken() != nil
    }

    func deleteToken() {
        deleteValue(for: tokenKey)
    }

    func deleteRefreshToken() {
        deleteValue(for: refreshTokenKey)
    }

    func deleteSession() {
        deleteToken()
        deleteRefreshToken()
    }
}
