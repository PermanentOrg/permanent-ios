//
//  AddLocationViewModel.swift
//  Permanent
//
//  Created by Flaviu Silaghi on 28.08.2023.

import Foundation
import MapKit
import GooglePlaces
import Combine

class AddLocationViewModel: ObservableObject {
    
    @Published var selectedPlace: City?
    @Published var selectedCoordinates: CLLocationCoordinate2D?
    @Published var searchedLocations: [City] = [City]()
    private var placesClient = GMSPlacesClient()
    
    @Published var debouncedText = "" {
        didSet {
//            googleSearchLocation()
        }
    }
    
    @Published var searchText = ""
    private var subscriptions = Set<AnyCancellable>()
    
    var token = GMSAutocompleteSessionToken.init()
    
    init() {
        $searchText
            .debounce(for: .seconds(2), scheduler: DispatchQueue.main)
                    .sink(receiveValue: { [weak self] t in
                        if self?.debouncedText != t {
                            self?.debouncedText = t
                        }
                    } )
                    .store(in: &subscriptions)
    }
    
    func googleSearchLocation() {
        guard debouncedText.isNotEmpty else { return }
        // Create a type filter.
        let filter = GMSAutocompleteFilter()
        placesClient.findAutocompletePredictions(fromQuery: debouncedText,
                                                  filter: filter,
                                                  sessionToken: token,
                                                  callback: { (results, error) in
            if let error = error {
              print("Autocomplete error: \(error)")
              return
            }
            if let results = results {
                self.searchedLocations = results.compactMap { item in
                    return City(id: item.placeID,
                                title: item.attributedPrimaryText.string,
                                subtitle: item.attributedSecondaryText?.string ?? "",
                                distance: self.getDistance(from: item.distanceMeters),
                                coordinate: nil)
                }
            }
        })
    }
    
    func fetchPlace() {
        guard var selectedPlace = selectedPlace else { return }
        placesClient.fetchPlace(fromPlaceID: selectedPlace.id,
                                placeFields: [.coordinate],
                                sessionToken: token) { place, error in
            selectedPlace.coordinate = place?.coordinate
            self.selectedCoordinates = place?.coordinate
            self.token = GMSAutocompleteSessionToken.init()
        }
    }
    
    func getDistance(from distance: NSNumber?) -> String? {
        guard let distance = distance else { return nil }
        return MKDistanceFormatter().string(fromDistance: distance.doubleValue)
    }
}
