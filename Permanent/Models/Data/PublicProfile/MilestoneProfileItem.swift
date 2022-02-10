//
//  MilestoneProfileItem.swift
//  Permanent
//
//  Created by Lucian Cerbu on 01.02.2022.
//

import Foundation
class MilestoneProfileItem: ProfileItemModel {
    var title: String? {
        get {
            return string1
        }
        set {
            string1 = newValue
        }
    }
    
    var startDate: String? {
        get {
            return day1
        }
        set {
            day1 = newValue
        }
    }
    
    var endDate: String? {
        get {
            return day2
        }
        set {
            day2 = newValue
        }
    }
    
    var description: String? {
        get {
            return string2
        }
        set {
            string2 = newValue
        }
    }
    
    var location: LocnVO? {
        get {
            return locnVOs?.first
        }
        set {
            guard let locnVO = newValue else { return }
            locnVOs = [locnVO]
        }
    }
    
    var locationFormated: String? {
        get {
            guard let locnVO = location else { return nil }
            
            let locationString = getAddressString([locnVO.streetNumber, locnVO.streetName, locnVO.locality, locnVO.country])
            
            return locationString
        }
        set {
            self.locationFormated = newValue
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
        super.init(fieldNameUI: FieldNameUI.milestone.rawValue)
        self.type = "type.widget.locn"
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}
