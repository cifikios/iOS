import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var isGPSEnabled = false
    @Published var userLocation: CoordinateWrapper?
    @Published var annotations: [CustomMapMarker] = []

    override init() {
        super.init()
        locationManager.delegate = self
        checkAuthorizationStatus()
    }

    func checkAuthorizationStatus() {
        let status = locationManager.authorizationStatus
        switch status {
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            isGPSEnabled = true
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            isGPSEnabled = false
            print("Location permission denied. Enable it in settings.")
        @unknown default:
            fatalError("Unknown location authorization status")
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            isGPSEnabled = true
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            isGPSEnabled = false
            print("Location permission denied. Enable it in settings.")
        case .notDetermined:
            break
        @unknown default:
            fatalError("Unknown location authorization status")
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        userLocation = CoordinateWrapper(coordinate: location.coordinate)
        annotations.append(CustomMapMarker(coordinate: location.coordinate))
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }

    func toggleGPS() {
        if isGPSEnabled {
            locationManager.stopUpdatingLocation()
        } else {
            locationManager.startUpdatingLocation()
        }
        isGPSEnabled.toggle()
    }
}
