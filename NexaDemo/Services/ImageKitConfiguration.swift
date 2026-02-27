import Foundation

struct ImageKitConfiguration: Sendable {
    let publicKey: String
    let urlEndpoint: String
    static let demoPublicKey = "public_FUM6drXF1NmNFqpF/lJFskxeZPU="
    static let demoPrivateKey = "private_8+l4Qu5/2+DkZlBtajdU005Jvu0="
    static let demoUrlEndpoint = "https://ik.imagekit.io/nexedemo/"

    static func load() -> ImageKitConfiguration? {
        return ImageKitConfiguration(publicKey: demoPublicKey, urlEndpoint: demoUrlEndpoint)
    }
}
