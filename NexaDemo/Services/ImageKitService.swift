import Foundation
import ImageKitIO
import UIKit

struct ImageKitService: Sendable {
    static let shared = ImageKitService()

    func uploadImage(
        image: UIImage,
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
        return try await withCheckedThrowingContinuation { continuation in
            ImageKit.shared.uploader().upload(
                file: image,
                token: token,
                fileName: fileName,
                useUniqueFilename: useUniqueFilename,
                tags: tags,
                folder: folder,
                isPrivateFile: isPrivateFile,
                customCoordinates: customCoordinates,
                responseFields: responseFields,
                progress: { uploadProgress in
                    print(uploadProgress)
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
                    print(uploadProgress)
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
}
