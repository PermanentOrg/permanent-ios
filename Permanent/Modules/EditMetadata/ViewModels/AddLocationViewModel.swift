//
//  AddLocationViewModel.swift
//  Permanent
//
//  Created by Flaviu Silaghi on 28.08.2023.
//

import Foundation
import MapKit
import GooglePlaces
import Combine

class AddLocationViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    
    @Published var selectedPlace: GMSAutocompletePrediction?
    
    @Published var selectedCoordinates: CLLocationCoordinate2D? {
        didSet {
            if let selectedCoordinates = selectedCoordinates, !isMovingToPickedPlace {
                validateLocation(lat: selectedCoordinates.latitude, long: selectedCoordinates.longitude)
            }
        }
    }
    private var isMovingToPickedPlace = false
    
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
    
    @Published var showConfirmation: Bool = false

    @Published var changesConfirmed: Bool = false

    /// Set when a location save fails so the sheet can surface an error instead of a silent
    /// dead-end (the sheet now stays open on failure, so it needs a retry cue).
    @Published var showError: Bool = false

    @Published var commonLocation: LocnVO? {
        didSet {
            if let commonLocation = commonLocation,
               let latitude = commonLocation.latitude,
               let longitude = commonLocation.longitude {
                selectedCoordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            } 
        }
    }
    
    var selectedFiles: [FileModel]

    /// Test seams for a save: one item's V2 PATCH and the V1 batch stand in for the server. Production
    /// leaves them nil.
    var patchRecordRequest: ItemLocationService.Patch?
    var updateV1Request: ((_ params: UpdateMultipleRecordsParams, _ completion: @escaping (Bool) -> Void) -> Void)?
    var pinAddressLookup = PinAddressLookup()

    init(selectedFiles: [FileModel], commonLocation: LocnVO?) {
        self.selectedFiles = selectedFiles
        self.commonLocation = commonLocation
        $searchText
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
                    .sink(receiveValue: { [weak self] t in
                        if self?.debouncedText != t && t != self?.getAddressString() {
                            self?.debouncedText = t
                        }
                    })
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
        placesClient.fetchPlace(fromPlaceID: selectedPlace.placeID, placeFields: PinAddressLookup.placeFields, sessionToken: token) { place, _ in
            if let place = place {
                if let picked = PinAddressLookup.locnVO(from: place) {
                    self.pickPlace(picked)
                } else {
                    self.selectedCoordinates = place.coordinate
                }

                self.token = GMSAutocompleteSessionToken.init()
            }
        }
    }

    /// A place picked from the search keeps its own name and address, so the map moves without the pin lookup.
    func pickPlace(_ location: LocnVO) {
        if let latitude = location.latitude, let longitude = location.longitude {
            isMovingToPickedPlace = true
            selectedCoordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            isMovingToPickedPlace = false
        }
        locnVO = location
    }

    func validateLocation(lat: Double, long: Double) {
        pinAddressLookup.locate(latitude: lat, longitude: long) { [weak self] locnVO in
            self?.locnVO = locnVO
        }
    }

    func update(completion: @escaping ((Bool) -> Void)) {
        isLoading = true
        guard let locnVO = locnVO else {
            updateV1(completion: completion)
            return
        }
        // One V2 PATCH per item, with the V1 batch as the failsafe.
        var service = ItemLocationService()
        if let patchRecordRequest = patchRecordRequest {
            service.patchRecord = patchRecordRequest
        }
        service.save(locnVO, to: selectedFiles) { [weak self] succeeded in
            if succeeded {
                self?.isLoading = false
                completion(true)
            } else {
                ItemLocationService.logger.notice("Batch location not saved through Stela V2, saving through V1.")
                self?.updateV1(completion: completion) // failsafe (resets isLoading)
            }
        }
    }

    private func updateV1(completion: @escaping ((Bool) -> Void)) {
        let params: UpdateMultipleRecordsParams = (files: selectedFiles, description: nil, location: locnVO)
        sendV1(params) { [weak self] succeeded in
            DispatchQueue.main.async {
                completion(succeeded)
                self?.isLoading = false
            }
        }
    }

    private func sendV1(_ params: UpdateMultipleRecordsParams, completion: @escaping (Bool) -> Void) {
        if let injected = updateV1Request {
            injected(params, completion)
            return
        }
        let apiOperation = APIOperation(FilesEndpoint.multipleUpdate(params: params))
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            if case .json = result {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    func getDistance(from distance: NSNumber?) -> String? {
        guard let distance = distance else { return nil }
        return MKDistanceFormatter().string(fromDistance: distance.doubleValue)
    }
    
    func getAddressString() -> String {
        locnVO?.addressText ?? ""
    }
}
