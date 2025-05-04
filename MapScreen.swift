import SwiftUI
import MapKit
import CoreLocation

struct MapScreen: View {
    @Binding var mapRegion: MKCoordinateRegion
    @Binding var sectorMarkers: [CLLocationCoordinate2D]
    var onMarkStartFinish: () -> Void
    var onMarkSector: () -> Void

    @State private var mapType: MKMapType = .standard
    @StateObject private var locationManager = LocationManager()

    var body: some View {
        VStack {
            CustomMapView(mapType: $mapType, region: $mapRegion, annotationItems: sectorMarkers.map { CustomMapMarker(coordinate: $0) })
                .frame(height: 400)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onEnded { value in
                            let location = value.location
                            let coordinate = convertToCoordinate(location: location)
                            sectorMarkers.append(coordinate)
                            print("Marker added at \(coordinate)")
                        }
                )

            // Buttons for map type (Standard, Satellite, Hybrid)
            HStack {
                Button(action: {
                    mapType = .standard
                }) {
                    Text("Standard")
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(mapType == .standard ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                Button(action: {
                    mapType = .satellite
                }) {
                    Text("Satellite")
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(mapType == .satellite ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                Button(action: {
                    mapType = .hybrid
                }) {
                    Text("Hybrid")
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(mapType == .hybrid ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()

            // Buttons for marking start/finish lap, sector, and reset markers
            HStack {
                Button(action: {
                    onMarkStartFinish()
                }) {
                    Text("Mark Start/Finish Lap")
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                Button(action: {
                    onMarkSector()
                }) {
                    Text("Mark Sector")
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                Button(action: {
                    sectorMarkers.removeAll()
                }) {
                    Text("Reset Markers")
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()

            Spacer()
        }
        .navigationTitle("Map")
        .padding()
        .onAppear {
            locationManager.checkAuthorizationStatus()
        }
        .onChange(of: locationManager.userLocation) { newLocation in
            if let location = newLocation {
                mapRegion = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            }
        }
    }

    private func convertToCoordinate(location: CGPoint) -> CLLocationCoordinate2D {
        return mapRegion.center
    }
}
