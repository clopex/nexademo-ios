import Foundation
import ImageKitIO
import Observation
import UIKit

@MainActor
@Observable
final class UserUpdateViewModel {
    private var didPrefill = false
    private var initialFullName = ""
    private var initialGender = ""
    private var initialPhone = ""
    private var initialPhoneDialCode = ""
    private var initialCountry = ""
    private var initialCity = ""
    private var initialAddress = ""
    private var initialProfileImageURL = ""
    var profileImage: UIImage?
    var selectedImageData: Data?
    var profileImageURL: String?
    var fullName = ""
    var gender = "Select"
    var phone = ""
    var phoneDialCode = "+1"
    var country = ""
    var city = ""
    var address = ""
    var isUploadingImage = false
    var isUpdatingProfile = false
    var imageStatusMessage: String?
    var updateStatusMessage: String?

    var hasChanges: Bool {
        if selectedImageData != nil || profileImage != nil {
            return true
        }

        let currentFullName = normalized(fullName) ?? ""
        let currentGender = gender == "Select" ? "" : gender
        let currentPhone = sanitizePhoneInput(phone)
        let currentDial = phoneDialCode
        let currentCountry = normalized(country) ?? ""
        let currentCity = normalized(city) ?? ""
        let currentAddress = normalized(address) ?? ""
        let currentProfileURL = profileImageURL ?? ""

        return currentFullName != initialFullName
            || currentGender != initialGender
            || currentPhone != initialPhone
            || currentDial != initialPhoneDialCode
            || currentCountry != initialCountry
            || currentCity != initialCity
            || currentAddress != initialAddress
            || currentProfileURL != initialProfileImageURL
    }

    private let tokenProvider = ImageKitLocalTokenProvider(
        publicKey: ImageKitConfiguration.demoPublicKey,
        privateKey: ImageKitConfiguration.demoPrivateKey
    )

    func setSelectedImage(_ image: UIImage?, data: Data?) {
        profileImage = image
        selectedImageData = data
        imageStatusMessage = nil
    }

    func uploadProfileImage() async {
        guard let data = selectedImageData ?? profileImage?.jpegData(compressionQuality: 0.9) else {
            imageStatusMessage = "Select an image first."
            return
        }
        isUploadingImage = true
        imageStatusMessage = nil

        do {
            let fileName = "upload_\(UUID().uuidString).jpg"
            let payload: [String: Any] = [
                "fileName": fileName,
                "useUniqueFileName": "true",
                "isPrivateFile": "false",
                "customCoordinates": "",
                "responseFields": ""
            ]
            let token = try tokenProvider.token(payload: payload, expiresIn: 60)
            let uploadImage = profileImage ?? UIImage(data: data)
            guard let uploadImage else {
                throw ImageKitServiceError.missingUploadResponse
            }
            let response = try await ImageKitService.shared.uploadImage(
                image: uploadImage,
                fileName: fileName,
                token: token,
                useUniqueFilename: true
            )
            profileImageURL = response.url
            if let url = response.url {
                print("ImageKit upload URL: \(url)")
            } else {
                print("ImageKit upload returned no URL.")
            }
            imageStatusMessage = "Upload complete."
        } catch {
            imageStatusMessage = error.localizedDescription
        }

        isUploadingImage = false
    }

    func deleteProfileImage() {
        profileImage = nil
        selectedImageData = nil
        profileImageURL = nil
        imageStatusMessage = "Image cleared."
    }

    func updateProfile() async -> User? {
        isUpdatingProfile = true
        updateStatusMessage = nil
        do {
            let cleanedPhone = sanitizePhoneInput(phone)
            let phoneValue = normalized(cleanedPhone)
            let combinedPhone = phoneValue.map { value in
                if value.hasPrefix("+") { return value }
                return "\(phoneDialCode)\(value)"
            }
            let payload = ProfileUpdateRequest(
                fullName: normalized(fullName),
                email: nil,
                gender: gender == "Select" ? nil : gender,
                phone: combinedPhone,
                country: normalized(country),
                city: normalized(city),
                address: normalized(address),
                profilePicture: profileImageURL
            )
            let user = try await ProfileService.shared.updateProfile(payload)
            updateStatusMessage = "Profile updated."
            isUpdatingProfile = false
            return user
        } catch {
            updateStatusMessage = error.localizedDescription
        }
        isUpdatingProfile = false
        return nil
    }

    private func normalized(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    func sanitizePhoneInput(_ value: String) -> String {
        value.filter { $0.isNumber }
    }

    func formatPhoneInput(_ value: String) -> String {
        let digits = sanitizePhoneInput(value)
        if digits.count <= 3 { return digits }
        if digits.count <= 6 {
            let prefix = digits.prefix(3)
            let rest = digits.dropFirst(3)
            return "\(prefix) \(rest)"
        }
        let prefix = digits.prefix(3)
        let middle = digits.dropFirst(3).prefix(3)
        let rest = digits.dropFirst(6)
        return "\(prefix) \(middle) \(rest)"
    }

    func prefill(from user: User?, force: Bool = false) {
        guard let user, !didPrefill || force else { return }
        fullName = user.fullName
        gender = user.gender ?? "Select"
        country = user.country ?? ""
        city = user.city ?? ""
        address = user.address ?? ""
        profileImageURL = user.profilePicture
        if user.profilePicture != nil {
            imageStatusMessage = "Profile image loaded."
        }
        if let phoneValue = user.phone {
            phone = formatPhoneInput(phoneValue)
            if phoneValue.hasPrefix("+") == false {
                phoneDialCode = "+1"
            } else {
                let digits = sanitizePhoneInput(phoneValue)
                if digits.count > 10 {
                    let dialDigits = digits.dropLast(10)
                    phoneDialCode = "+\(dialDigits)"
                    phone = formatPhoneInput(String(digits.suffix(10)))
                } else {
                    phone = formatPhoneInput(String(digits))
                }
            }
        }
        didPrefill = true
        setBaselineFromCurrent()
    }

    private func setBaselineFromCurrent() {
        initialFullName = normalized(fullName) ?? ""
        initialGender = gender == "Select" ? "" : gender
        initialPhone = sanitizePhoneInput(phone)
        initialPhoneDialCode = phoneDialCode
        initialCountry = normalized(country) ?? ""
        initialCity = normalized(city) ?? ""
        initialAddress = normalized(address) ?? ""
        initialProfileImageURL = profileImageURL ?? ""
    }
}
