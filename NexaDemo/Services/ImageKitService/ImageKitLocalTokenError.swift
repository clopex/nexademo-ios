import Foundation

enum ImageKitLocalTokenError: LocalizedError, Sendable {
    case missingKeys
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .missingKeys:
            return "Missing ImageKit keys."
        case .encodingFailed:
            return "Failed to build upload token."
        }
    }
}
