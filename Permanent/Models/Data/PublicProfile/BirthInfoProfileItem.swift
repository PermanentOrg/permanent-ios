//
//  BirthInfoProfileItem.swift
//  Permanent
//
//  Created by Lucian Cerbu on 04.01.2022.
//

import Foundation
class BirthInfoProfileItem: ProfileItemModel {
    var birthDate: String? {
        get {
            return day1
        }
        set {
            day1 = newValue
        }
    }
    var birthLocation: LocnVO? {
        get {
            return locnVOs?.first
        }
        set {
            guard let locnVO = newValue else { return }
            locnVOs = [locnVO]
        }
    }
    
    var birthLocationFormated: String? {
        get {
            guard let locnVO = birthLocation else { return nil }
            
            let locationString = getAddressString([locnVO.streetNumber, locnVO.streetName, locnVO.locality, locnVO.country])
            
            return locationString
        }
        set {
            self.birthLocationFormated = newValue
        }
    }
    
    func getAddressString(_ items: [String?]) -> String {
        var address = items.compactMap { $0 }.joined(separator: ", ")
        address.isEmpty ? (address = "Choose a location".localized()) : ()

        return address
    }
}
