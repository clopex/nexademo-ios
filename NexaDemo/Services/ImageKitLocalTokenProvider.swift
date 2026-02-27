import CryptoKit
import Foundation

struct ImageKitLocalTokenProvider: Sendable {
    let publicKey: String
    let privateKey: String

    func token(payload: [String: Any], expiresIn: TimeInterval = 60) throws -> String {
        guard !publicKey.isEmpty, !privateKey.isEmpty else {
            throw ImageKitLocalTokenError.missingKeys
        }

        let header: [String: Any] = [
            "alg": "HS256",
            "typ": "JWT",
            "kid": publicKey
        ]

        var body: [String: Any] = payload
        let now = Date().timeIntervalSince1970
        let iat = Int(now)
        let exp = Int(now + expiresIn)
        body["iat"] = iat
        body["exp"] = exp

        guard let headerData = try? JSONSerialization.data(withJSONObject: header),
              let bodyData = try? JSONSerialization.data(withJSONObject: body) else {
            throw ImageKitLocalTokenError.encodingFailed
        }

        let headerPart = base64URL(headerData)
        let bodyPart = base64URL(bodyData)
        let signingInput = "\(headerPart).\(bodyPart)"
        let signature = HMAC<SHA256>.authenticationCode(
            for: Data(signingInput.utf8),
            using: SymmetricKey(data: Data(privateKey.utf8))
        )
        let signaturePart = base64URL(Data(signature))
        return "\(signingInput).\(signaturePart)"
    }

    private func base64URL(_ data: Data) -> String {
        data.base64EncodedString()
            .replacing("+", with: "-")
            .replacing("/", with: "_")
            .replacing("=", with: "")
    }
}
