import CoreLocation

// Wrapper for CLLocationCoordinate2D that conforms to Equatable
struct CoordinateWrapper: Equatable {
    let coordinate: CLLocationCoordinate2D

    // Implement Equatable conformance
    static func == (lhs: CoordinateWrapper, rhs: CoordinateWrapper) -> Bool {
        return lhs.coordinate.latitude == rhs.coordinate.latitude &&
               lhs.coordinate.longitude == rhs.coordinate.longitude
    }
}
