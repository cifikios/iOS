import SwiftUI
import MapKit

struct GPSTrackingView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )

    var body: some View {
        Map(coordinateRegion: $region, annotationItems: locationManager.annotations) { location in
            MapAnnotation(coordinate: location.coordinate) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 10, height: 10)
            }
        }
        .onChange(of: locationManager.userLocation) { newLocation in
            if let coordinate = newLocation?.coordinate {
                region.center = coordinate
            }
        }
        .onAppear {
            // checkAuthorizationStatus is already called in LocationManager's init
        }
    }
}
