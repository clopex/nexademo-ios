import Foundation

enum ImageKitServiceError: LocalizedError, Sendable {
    case missingConfiguration
    case missingUploadResponse

    var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return "ImageKit is not configured."
        case .missingUploadResponse:
            return "Upload finished without a response."
        }
    }
}
