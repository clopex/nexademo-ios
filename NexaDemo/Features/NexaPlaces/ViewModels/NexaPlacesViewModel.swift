import CoreLocation
import Foundation
import MapKit
import Observation
import SwiftUI

@Observable
@MainActor
final class NexaPlacesViewModel {
    var cameraPosition: MapCameraPosition = .automatic
    var searchText = ""
    var isSearching = false
    var results: [NexaPlaceSearchResult] = []
    var selectedResult: NexaPlaceSearchResult?
    var errorMessage: String?
    var locationStatus: CLAuthorizationStatus = .notDetermined

    private let initialQuery: String?
    private let intentParser = NexaPlacesIntentParser()
    private let locationService = NexaPlacesLocationService()
    private let searchService = NexaPlacesSearchService()
    private var userLocation: CLLocation?
    private var activeRegion: MKCoordinateRegion?
    private var hasCenteredOnUser = false
    private var didRunInitialSearch = false

    init(initialQuery: String?) {
        self.initialQuery = initialQuery?.trimmingCharacters(in: .whitespacesAndNewlines)

        locationService.onAuthorizationChange = { [weak self] status in
            self?.locationStatus = status
        }

        locationService.onLocationChange = { [weak self] location in
            guard let self else { return }
            self.userLocation = location

            if let location, self.hasCenteredOnUser == false {
                self.centerMap(on: location.coordinate, distance: 1800)
                self.hasCenteredOnUser = true
            }
        }
    }

    var statusMessage: String {
        if let errorMessage {
            return errorMessage
        }

        if isSearching {
            return "Searching nearby places..."
        }

        if let selectedResult {
            return selectedResult.name
        }

        if results.isEmpty {
            return "Try \"Find coffee shops near me\""
        }

        return "\(results.count) places found"
    }

    func prepare() async {
        locationService.requestAccessIfNeeded()

        if let currentLocation = locationService.currentLocation, hasCenteredOnUser == false {
            userLocation = currentLocation
            centerMap(on: currentLocation.coordinate, distance: 1800)
            hasCenteredOnUser = true
        }

        guard didRunInitialSearch == false,
              let initialQuery,
              initialQuery.isEmpty == false else {
            return
        }

        didRunInitialSearch = true
        searchText = initialQuery
        await runSearch(for: initialQuery)
    }

    func submitSearch() async {
        await runSearch(for: searchText)
    }

    func search(for query: String) async {
        await runSearch(for: query)
    }

    func select(_ result: NexaPlaceSearchResult) {
        selectedResult = result
        centerMap(on: result.coordinate, distance: 1200)
    }

    func recenterOnUser() {
        locationService.requestCurrentLocation()

        if let userLocation {
            centerMap(on: userLocation.coordinate, distance: 1800)
        }
    }

    func resetSearch() {
        searchText = ""
        results = []
        selectedResult = nil
        errorMessage = nil
        recenterOnUser()
    }

    func openDirections() {
        guard let selectedResult else { return }
        searchService.openDirections(to: selectedResult)
    }

    func openInMaps() {
        guard let selectedResult else { return }
        searchService.openInMaps(selectedResult)
    }

    func stop() {}

    private func runSearch(for query: String) async {
        let intent = intentParser.parse(query)
        guard intent.searchQuery.isEmpty == false else { return }

        searchText = intent.spokenQuery.isEmpty ? intent.searchQuery : intent.spokenQuery
        isSearching = true
        errorMessage = nil

        do {
            let foundResults = try await searchService.search(
                query: intent.searchQuery,
                region: preferredRegion()
            )
            results = foundResults
            selectedResult = foundResults.first
            updateMap(for: foundResults)

            if foundResults.isEmpty {
                errorMessage = "No places matched \"\(intent.searchQuery)\"."
            }
        } catch {
            errorMessage = "Search failed. Please try again."
        }

        isSearching = false
    }

    private func preferredRegion() -> MKCoordinateRegion? {
        if let userLocation {
            return MKCoordinateRegion(
                center: userLocation.coordinate,
                latitudinalMeters: 6000,
                longitudinalMeters: 6000
            )
        }

        return activeRegion
    }

    private func centerMap(on coordinate: CLLocationCoordinate2D, distance: CLLocationDistance) {
        let region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: distance,
            longitudinalMeters: distance
        )
        activeRegion = region
        cameraPosition = .region(region)
    }

    private func updateMap(for results: [NexaPlaceSearchResult]) {
        guard results.isEmpty == false else {
            if let userLocation {
                centerMap(on: userLocation.coordinate, distance: 1800)
            }
            return
        }

        var latitudes = results.map(\.coordinate.latitude)
        var longitudes = results.map(\.coordinate.longitude)

        if let userLocation {
            latitudes.append(userLocation.coordinate.latitude)
            longitudes.append(userLocation.coordinate.longitude)
        }

        guard
            let minLatitude = latitudes.min(),
            let maxLatitude = latitudes.max(),
            let minLongitude = longitudes.min(),
            let maxLongitude = longitudes.max()
        else {
            return
        }

        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: (minLatitude + maxLatitude) / 2,
                longitude: (minLongitude + maxLongitude) / 2
            ),
            span: MKCoordinateSpan(
                latitudeDelta: max((maxLatitude - minLatitude) * 1.55, 0.02),
                longitudeDelta: max((maxLongitude - minLongitude) * 1.55, 0.02)
            )
        )

        activeRegion = region
        cameraPosition = .region(region)
    }
}
