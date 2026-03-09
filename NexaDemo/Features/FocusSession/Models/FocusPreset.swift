import Foundation

enum FocusPreset: String, Codable, Hashable, CaseIterable, Sendable, Identifiable {
    case study
    case deepWork
    case reading
    case callPrep
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .study:
            return "Study Focus"
        case .deepWork:
            return "Deep Work"
        case .reading:
            return "Reading Mode"
        case .callPrep:
            return "Call Prep"
        case .custom:
            return "Custom Focus"
        }
    }

    var suggestedBlocks: [String] {
        switch self {
        case .study:
            return ["Social", "Entertainment", "Games"]
        case .deepWork:
            return ["Social", "Messaging", "Video"]
        case .reading:
            return ["Social", "Games", "Video"]
        case .callPrep:
            return ["Social", "Video", "Messaging"]
        case .custom:
            return ["Your choice"]
        }
    }

    var systemImage: String {
        switch self {
        case .study:
            return "book.closed.fill"
        case .deepWork:
            return "brain.head.profile"
        case .reading:
            return "text.book.closed.fill"
        case .callPrep:
            return "phone.badge.waveform.fill"
        case .custom:
            return "slider.horizontal.3"
        }
    }
}
