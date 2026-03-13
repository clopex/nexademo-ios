import CoreLocation
import Foundation

@MainActor
final class NexaPlacesLocationService: NSObject, CLLocationManagerDelegate {
    var onLocationChange: ((CLLocation?) -> Void)?
    var onAuthorizationChange: ((CLAuthorizationStatus) -> Void)?

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    var currentLocation: CLLocation? {
        manager.location
    }

    func requestAccessIfNeeded() {
        let status = manager.authorizationStatus
        onAuthorizationChange?(status)

        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            break
        @unknown default:
            break
        }
    }

    func requestCurrentLocation() {
        manager.requestLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        onAuthorizationChange?(status)

        if status == .authorizedAlways || status == .authorizedWhenInUse {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        onLocationChange?(locations.last)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        if (error as? CLError)?.code == .locationUnknown {
            return
        }

        onLocationChange?(manager.location)
    }
}
