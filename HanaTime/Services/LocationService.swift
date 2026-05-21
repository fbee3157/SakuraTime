import Foundation
import CoreLocation
import Combine

final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {

    static let shared = LocationService()

    @Published var userLocation: CLLocation?
    @Published var locationName: String = "点击定位"
    @Published var isLocating = false
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let manager = CLLocationManager()

    override private init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestLocation() {
        isLocating = true
        locationName = "定位中…"
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            isLocating = false
            locationName = "无定位权限"
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.first else { return }
        userLocation = loc
        isLocating = false
        let lat = String(format: "%.4f", loc.coordinate.latitude)
        let lng = String(format: "%.4f", loc.coordinate.longitude)
        locationName = "\(lat)°N, \(lng)°E"
        // Reverse geocode
        CLGeocoder().reverseGeocodeLocation(loc, preferredLocale: Locale(identifier: "zh_CN")) { [weak self] placemarks, _ in
            if let place = placemarks?.first {
                let city = place.locality ?? place.administrativeArea ?? ""
                if !city.isEmpty {
                    self?.locationName = "\(city)  \(lat)°N"
                }
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isLocating = false
        locationName = "点击定位"
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if manager.authorizationStatus == .authorizedWhenInUse {
            manager.requestLocation()
        }
    }

    func distance(to spot: CherrySpot) -> Double? {
        guard let loc = userLocation else { return nil }
        let spotLoc = CLLocation(latitude: spot.latitude, longitude: spot.longitude)
        return loc.distance(from: spotLoc) / 1000 // km
    }
}
