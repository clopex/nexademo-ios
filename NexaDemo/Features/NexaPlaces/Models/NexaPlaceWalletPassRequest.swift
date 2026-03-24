import CoreLocation
import Foundation

struct NexaPlaceWalletPassRequest: Encodable, Sendable {
    let name: String
    let address: String
    let categoryName: String?
    let latitude: Double
    let longitude: Double
    let phoneNumber: String?
    let appLaunchURL: String?
    let planTitle: String
    let scheduledAt: String
    let scheduledDateText: String
    let scheduledTimeText: String
    let note: String?

    init(result: NexaPlaceSearchResult, planTitle: String, scheduledAt: Date, note: String) {
        name = result.name
        address = result.address
        categoryName = result.categoryName
        latitude = result.coordinate.latitude
        longitude = result.coordinate.longitude
        phoneNumber = result.phoneNumber
        appLaunchURL = Self.makeAppLaunchURL(for: result)?.absoluteString
        self.planTitle = planTitle
        self.scheduledAt = Self.iso8601Formatter.string(from: scheduledAt)
        scheduledDateText = scheduledAt.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
        scheduledTimeText = scheduledAt.formatted(.dateTime.hour().minute())
        self.note = note.isEmpty ? nil : note
    }

    private static func makeAppLaunchURL(for result: NexaPlaceSearchResult) -> URL? {
        var components = URLComponents()
        components.scheme = "nexademo"
        components.host = "places"
        components.queryItems = [
            URLQueryItem(name: "query", value: result.name)
        ]
        return components.url
    }

    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}
