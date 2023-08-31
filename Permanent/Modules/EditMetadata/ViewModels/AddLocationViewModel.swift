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
    
    @Published var isLoading: Bool = false
    
    @Published var selectedPlace: City? {
        didSet {
            if let selectedPlace = selectedPlace {
                searchText = selectedPlace.title
            }
        }
    }
    
    @Published var selectedCoordinates: CLLocationCoordinate2D?
    @Published var searchedLocations: [City] = [City]()
    
    private var placesClient = GMSPlacesClient()
    
    @Published var debouncedText = "" {
        didSet {
            googleSearchLocation()
        }
    }
    
    @Published var searchText = ""
    private var subscriptions = Set<AnyCancellable>()
    
    @Published var locnVO: LocnVO?
    
    var token = GMSAutocompleteSessionToken.init()
    
    var selectedFiles: [FileModel]
    
    init(selectedFiles: [FileModel]) {
        self.selectedFiles = selectedFiles
        $searchText
            .debounce(for: .seconds(2), scheduler: DispatchQueue.main)
                    .sink(receiveValue: { [weak self] t in
                        if self?.debouncedText != t && t != self?.selectedPlace?.title {
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
            if let place = place {
                selectedPlace.coordinate = place.coordinate
                self.selectedCoordinates = place.coordinate
                self.validateLocation(lat: place.coordinate.latitude, long: place.coordinate.longitude)
                
                self.token = GMSAutocompleteSessionToken.init()
            }
        }
    }
    
    func validateLocation(lat: Double, long: Double) {
        let params: GeomapLatLongParams = (lat, long)
        let apiOperation = APIOperation(LocationEndpoint.geomapLatLong(params: params))
        
        apiOperation.execute(in: APIRequestDispatcher()) {[weak self] result in
            switch result {
            case .json(let json, _):
                guard let model: APIResults<LocnVOData> = JSONHelper.decoding(from: json, with: APIResults<LocnVOData>.decoder), model.isSuccessful else {
                    self?.locnVO = nil
                    return
                }
                let locnVO = model.results.first?.data?.first?.locnVO
                self?.locnVO = locnVO
            default:
                self?.locnVO = nil
            }
        }
    }
    
    func update(completion: @escaping ((Bool) -> Void)) {
        isLoading = true
        let params: UpdateMultipleRecordsParams = (files: selectedFiles, description: nil, location: locnVO)
        let apiOperation = APIOperation(FilesEndpoint.multipleUpdate(params: params))
        
        apiOperation.execute(in: APIRequestDispatcher()) {[weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .json( _, _):
                    completion(true)
                default:
                    completion(false)
                }
                self?.isLoading = false
            }
        }
    }
    
    func getDistance(from distance: NSNumber?) -> String? {
        guard let distance = distance else { return nil }
        return MKDistanceFormatter().string(fromDistance: distance.doubleValue)
    }
}
