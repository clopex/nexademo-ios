import Foundation

enum FocusSessionError: LocalizedError {
    case unavailable
    case authorizationDenied
    case missingSelection
    case invalidDuration

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "Focus sessions are unavailable on this device."
        case .authorizationDenied:
            return "Screen Time access is required to start a focus session."
        case .missingSelection:
            return "Choose at least one app, category, or website to block."
        case .invalidDuration:
            return "Choose a valid duration before starting the session."
        }
    }
}
