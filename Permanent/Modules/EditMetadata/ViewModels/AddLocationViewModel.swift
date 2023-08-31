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
    
    @Published var selectedPlace: GMSAutocompletePrediction?
    
    @Published var selectedCoordinates: CLLocationCoordinate2D? {
        didSet {
            if let selectedCoordinates = selectedCoordinates {
                validateLocation(lat: selectedCoordinates.latitude, long: selectedCoordinates.longitude)
            }
        }
    }
    
    @Published var searchedLocations: [GMSAutocompletePrediction] = [GMSAutocompletePrediction]()
    
    private var placesClient = GMSPlacesClient()
    
    @Published var debouncedText = "" {
        didSet {
            googleSearchLocation()
        }
    }
    
    @Published var searchText = ""
    private var subscriptions = Set<AnyCancellable>()
    
    @Published var locnVO: LocnVO? {
        didSet {
            searchText = getAddressString()
        }
    }
    
    var token = GMSAutocompleteSessionToken.init()
    
    var selectedFiles: [FileModel]
    
    init(selectedFiles: [FileModel]) {
        self.selectedFiles = selectedFiles
        $searchText
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
                    .sink(receiveValue: { [weak self] t in
                        if self?.debouncedText != t && t != self?.getAddressString() {
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
                self.searchedLocations = results
            }
        })
    }
    
    func fetchPlace() {
        guard var selectedPlace = selectedPlace else { return }
        placesClient.fetchPlace(fromPlaceID: selectedPlace.placeID,
                                placeFields: [.coordinate],
                                sessionToken: token) { place, error in
            if let place = place {
                self.selectedCoordinates = place.coordinate
                
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
    
    func getAddressString() -> String {
        let items = [locnVO?.streetNumber, locnVO?.streetName, locnVO?.locality, locnVO?.country]
        let address = items.compactMap { $0 }.joined(separator: ", ")
        return address
    }
}
