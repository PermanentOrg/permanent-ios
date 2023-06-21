//
//  GenderProfileItem.swift
//  Permanent
//
//  Created by Lucian Cerbu on 04.01.2022.
//

import Foundation

class GenderProfileItem: ProfileItemModel {
    var personGender: String? {
        get {
            return string1
        }
        set {
            string1 = newValue
        }
    }
    
    init() {
        super.init(fieldNameUI: FieldNameUI.profileGender.rawValue)
        self.type = "type.widget.string"
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}
