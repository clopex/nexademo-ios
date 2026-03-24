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

    init(result: NexaPlaceSearchResult) {
        name = result.name
        address = result.address
        categoryName = result.categoryName
        latitude = result.coordinate.latitude
        longitude = result.coordinate.longitude
        phoneNumber = result.phoneNumber
        appLaunchURL = Self.makeAppLaunchURL(for: result)?.absoluteString
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
}
