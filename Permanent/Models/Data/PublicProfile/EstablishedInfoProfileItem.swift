//
//  EstablishedInfoProfileItem.swift
//  Permanent
//
//  Created by Lucian Cerbu on 26.01.2022.
//

import Foundation
class EstablishedInfoProfileItem: ProfileItemModel {
    var establishedDate: String? {
        get {
            return day1
        }
        set {
            day1 = newValue
        }
    }
    
    var establishedLocation: LocnVO? {
        get {
            return locnVOs?.first
        }
        set {
            guard let locnVO = newValue else { return }
            locnVOs = [locnVO]
        }
    }
    
    var establishedLocationFormated: String? {
        get {
            guard let locnVO = establishedLocation else { return nil }
            
            let locationString = getAddressString([locnVO.streetNumber, locnVO.streetName, locnVO.locality, locnVO.country])
            
            return locationString
        }
        set {
            self.establishedLocationFormated = newValue
        }
    }
    
    var locationID: Int? {
        get {
            return locnId1
        }
        set {
            locnId1 = newValue
        }
    }
    
    func getAddressString(_ items: [String?]) -> String {
        var address = items.compactMap { $0 }.joined(separator: ", ")
        address.isEmpty ? (address = "Choose a location".localized()) : ()

        return address
    }
    
    init() {
        super.init(fieldNameUI: FieldNameUI.establishedInfo.rawValue)
        self.type = "type.widget.string"
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}
