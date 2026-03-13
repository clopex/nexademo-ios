import Foundation
import MapKit

struct NexaPlaceSearchResult: Identifiable, Equatable {
    let id = UUID()
    let mapItem: MKMapItem
    let name: String
    let coordinate: CLLocationCoordinate2D
    let address: String
    let categoryName: String?
    let phoneNumber: String?

    init(mapItem: MKMapItem) {
        self.mapItem = mapItem
        self.name = mapItem.name ?? "Unnamed Place"
        self.coordinate = mapItem.location.coordinate
        self.address = mapItem.address?.shortAddress
            ?? mapItem.addressRepresentations?.fullAddress(includingRegion: false, singleLine: true)
            ?? mapItem.address?.fullAddress
            ?? ""
        self.categoryName = mapItem.pointOfInterestCategory?.rawValue
            .replacing("_", with: " ")
            .capitalized
        self.phoneNumber = mapItem.phoneNumber
    }

    static func == (lhs: NexaPlaceSearchResult, rhs: NexaPlaceSearchResult) -> Bool {
        lhs.id == rhs.id
    }
}
