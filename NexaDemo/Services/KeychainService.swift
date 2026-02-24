import Foundation
import Security

actor KeychainService {
    static let shared = KeychainService()

    private let tokenKey = "nexademo_jwt_token"
    private let service = "com.nexa.NexaDemo"

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tokenKey,
            kSecAttrService as String: service
        ]
    }

    func saveToken(_ token: String) {
        var query = baseQuery()
        query[kSecValueData as String] = token.data(using: .utf8)
        query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    func getToken() -> String? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    func deleteToken() {
        let query = baseQuery()
        SecItemDelete(query as CFDictionary)
    }
}
