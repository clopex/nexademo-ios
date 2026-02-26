import Foundation
import ImageKitIO

struct ImageKitService: Sendable {
    static let shared = ImageKitService(configuration: ImageKitConfiguration.load())

    private let configuration: ImageKitConfiguration?

    init(configuration: ImageKitConfiguration?) {
        self.configuration = configuration
    }

    func uploadImage(
        data: Data,
        fileName: String,
        token: String,
        useUniqueFilename: Bool = true,
        tags: [String]? = nil,
        folder: String? = nil,
        isPrivateFile: Bool = false,
        customCoordinates: String = "",
        responseFields: String = "",
        progress: ((Progress) -> Void)? = nil
    ) async throws -> UploadAPIResponse {
        let config = try resolvedConfiguration()
        ImageKit.init(
            publicKey: config.publicKey,
            urlEndpoint: config.urlEndpoint,
            transformationPosition: .PATH
        )

        return try await withCheckedThrowingContinuation { continuation in
            ImageKit.shared.uploader().upload(
                file: data,
                token: token,
                fileName: fileName,
                useUniqueFilename: useUniqueFilename,
                tags: tags,
                folder: folder,
                isPrivateFile: isPrivateFile,
                customCoordinates: customCoordinates,
                responseFields: responseFields,
                progress: { uploadProgress in
                    progress?(uploadProgress)
                },
                completion: { result in
                    switch result {
                    case .success(let response):
                        let uploadResponse = response.1
                        if let uploadResponse {
                            continuation.resume(returning: uploadResponse)
                        } else {
                            continuation.resume(throwing: ImageKitServiceError.missingUploadResponse)
                        }
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            )
        }
    }

    private func resolvedConfiguration() throws -> ImageKitConfiguration {
        guard let configuration else {
            throw ImageKitServiceError.missingConfiguration
        }
        return configuration
    }
}
