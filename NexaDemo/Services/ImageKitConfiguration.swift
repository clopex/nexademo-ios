import Foundation

struct ImageKitConfiguration: Sendable {
    let publicKey: String
    let urlEndpoint: String

    static func load() -> ImageKitConfiguration? {
        guard let publicKey = Bundle.main.object(forInfoDictionaryKey: "IMAGEKIT_PUBLIC_KEY") as? String,
              let urlEndpoint = Bundle.main.object(forInfoDictionaryKey: "IMAGEKIT_URL_ENDPOINT") as? String,
              !publicKey.isEmpty,
              !urlEndpoint.isEmpty else {
            return nil
        }
        return ImageKitConfiguration(publicKey: publicKey, urlEndpoint: urlEndpoint)
    }
}
