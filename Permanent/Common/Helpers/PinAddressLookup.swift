//
//  PinAddressLookup.swift
//  Permanent
//
//  Created by Lucian Cerbu on 19.10.2026.
//

import Foundation
import CoreLocation
import GoogleMaps
import GooglePlaces

/// Turns a map pin into an address on the phone. The old server lookup answers only when the phone lookup fails.
struct PinAddressLookup {
    typealias Address = (street: String?, city: String?, state: String?, postalCode: String?, country: String?)
    typealias AddressPart = (types: [String], name: String)

    /// What a place picked from the search must carry to be saved without a lookup.
    static let placeFields: GMSPlaceField = [.name, .coordinate, .addressComponents]
    typealias Geocode = (_ coordinate: CLLocationCoordinate2D, _ completion: @escaping (Result<Address?, Error>) -> Void) -> Void
    typealias ServerLookup = (_ latitude: Double, _ longitude: Double, _ completion: @escaping (LocnVO?) -> Void) -> Void

    private static let geocoder = GMSGeocoder()

    var geocode: Geocode = { coordinate, completion in
        Self.geocoder.reverseGeocodeCoordinate(coordinate) { response, error in
            if let error {
                completion(.failure(error))
                return
            }
            let first = response?.firstResult()
            completion(.success(first.map { ($0.thoroughfare, $0.locality, $0.administrativeArea, $0.postalCode, $0.country) }))
        }
    }
    var serverLookup: ServerLookup = { latitude, longitude, completion in
        let params: GeomapLatLongParams = (latitude, longitude)
        let operation = APIOperation(LocationEndpoint.geomapLatLong(params: params))
        operation.execute(in: APIRequestDispatcher()) { result in
            guard case .json(let json, _) = result,
                  let model: APIResults<LocnVOData> = JSONHelper.decoding(from: json, with: APIResults<LocnVOData>.decoder),
                  model.isSuccessful else {
                completion(nil)
                return
            }
            completion(model.results.first?.data?.first?.locnVO)
        }
    }

    /// Nil only when the phone lookup and the server lookup both fail.
    func locate(latitude: Double, longitude: Double, completion: @escaping (LocnVO?) -> Void) {
        let serverLookup = serverLookup
        geocode(CLLocationCoordinate2D(latitude: latitude, longitude: longitude)) { result in
            switch result {
            case .success(let address):
                completion(Self.locnVO(from: address, latitude: latitude, longitude: longitude))

            case .failure(let error):
                ItemLocationService.logger.notice("Pin lookup on the phone failed, using the server lookup: \(error.localizedDescription, privacy: .public)")
                serverLookup(latitude, longitude, completion)
            }
        }
    }

    /// A pin with no address, such as one in open land, still gets its coordinates, so it can be saved.
    static func locnVO(from address: Address?, latitude: Double, longitude: Double) -> LocnVO? {
        let parts: [String: String?] = [
            "streetName": address?.street,
            "locality": address?.city,
            "adminOneName": address?.state,
            "postalCode": address?.postalCode,
            "country": address?.country
        ]
        var locn: [String: Any] = parts.compactMapValues { $0 }.filter { !$0.value.isEmpty }
        locn["latitude"] = latitude
        locn["longitude"] = longitude
        return JSONHelper.decoding(from: locn, with: LocnVO.decoder)
    }

    /// A place picked from the search keeps its own name and address parts, as the web saves it.
    static func locnVO(placeName: String?, parts: [AddressPart], latitude: Double, longitude: Double) -> LocnVO? {
        func part(_ type: String) -> String? {
            parts.first { $0.types.contains(type) }?.name
        }

        let fields: [String: String?] = [
            "displayName": placeName,
            "streetNumber": part("street_number"),
            "streetName": part("route"),
            "locality": part("locality"),
            "adminOneName": part("administrative_area_level_1"),
            "postalCode": part("postal_code"),
            "country": part("country")
        ]
        var locn: [String: Any] = fields.compactMapValues { $0 }.filter { !$0.value.isEmpty }
        locn["latitude"] = latitude
        locn["longitude"] = longitude
        return JSONHelper.decoding(from: locn, with: LocnVO.decoder)
    }

    static func locnVO(from place: GMSPlace) -> LocnVO? {
        let parts = (place.addressComponents ?? []).map { AddressPart(types: $0.types, name: $0.name) }
        return locnVO(placeName: place.name, parts: parts, latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
    }
}
