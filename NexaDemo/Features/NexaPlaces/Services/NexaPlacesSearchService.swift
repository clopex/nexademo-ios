import Foundation
import MapKit

struct NexaPlacesSearchService: Sendable {
    func search(query: String, region: MKCoordinateRegion?) async throws -> [NexaPlaceSearchResult] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = .pointOfInterest

        if let region {
            request.region = region
        }

        let response = try await MKLocalSearch(request: request).start()
        return response.mapItems.map(NexaPlaceSearchResult.init)
    }

    func openDirections(to result: NexaPlaceSearchResult) {
        result.mapItem.openInMaps(
            launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        )
    }

    func openInMaps(_ result: NexaPlaceSearchResult) {
        result.mapItem.openInMaps()
    }
}
