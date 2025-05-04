import Foundation
import MapKit

struct CustomMapMarker: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}
