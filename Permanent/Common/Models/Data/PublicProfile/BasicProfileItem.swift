//
//  BasicProfileItem.swift
//  Permanent
//
//  Created by Lucian Cerbu on 03.01.2022.
//

import Foundation

class BasicProfileItem: ProfileItemModel {   
    var archiveName: String? {
        get {
            return string1
        }
        set {
            string1 = newValue
        }
    }
    
    var fullName: String? {
        get {
            return string2
        }
        set {
            string2 = newValue
        }
    }
    
    var nickname: String? {
        get {
            return string3
        }
        set {
            string3 = newValue
        }
    }
    
    init() {
        super.init(fieldNameUI: FieldNameUI.basic.rawValue)
        self.type = "type.profile_item.basic"
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}
