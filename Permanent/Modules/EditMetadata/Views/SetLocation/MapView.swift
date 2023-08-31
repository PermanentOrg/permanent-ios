//
//  MapView.swift
//  Permanent
//
//  Created by Flaviu Silaghi on 24.08.2023.

import SwiftUI
import GoogleMaps

struct MapView: UIViewRepresentable {
    
    @Binding var coordinates: CLLocationCoordinate2D?
    let marker: GMSMarker = GMSMarker(position: CLLocationCoordinate2D(latitude: 0, longitude: 0))

    func makeUIView(context: Context) -> GMSMapView {
        let camera = GMSCameraPosition.camera(withLatitude: 0, longitude: 0, zoom: 6.0)
        let mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        mapView.delegate = context.coordinator
        
        return mapView
    }
    
    func updateUIView(_ uiView: GMSMapView, context: Context) {
        if let coordinates = coordinates {
            let cameraUpdate = GMSCameraUpdate.setTarget(coordinates, zoom: uiView.camera.zoom)
            uiView.animate(with: cameraUpdate)
            uiView.clear()
            marker.position = coordinates
            marker.map = uiView
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, GMSMapViewDelegate {
        
        var parent: MapView
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: GMSMapView, didLongPressAt coordinate: CLLocationCoordinate2D) {
            parent.coordinates = coordinate
        }
    }
}
