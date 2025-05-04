import SwiftUI
import MapKit

struct CustomMapView: UIViewRepresentable {
    @Binding var mapType: MKMapType
    @Binding var region: MKCoordinateRegion
    var annotationItems: [CustomMapMarker]

    // Initializer
    init(mapType: Binding<MKMapType>, region: Binding<MKCoordinateRegion>, annotationItems: [CustomMapMarker]) {
        self._mapType = mapType
        self._region = region
        self.annotationItems = annotationItems
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.setRegion(region, animated: true)
        mapView.mapType = mapType
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.isUserInteractionEnabled = true
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.mapType = mapType
        mapView.setRegion(region, animated: true)

        // Update annotations
        mapView.removeAnnotations(mapView.annotations)
        for item in annotationItems {
            let annotation = MKPointAnnotation()
            annotation.coordinate = item.coordinate
            mapView.addAnnotation(annotation)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: CustomMapView

        init(_ parent: CustomMapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            print("Map region changed: \(mapView.region)")
        }
    }
}
