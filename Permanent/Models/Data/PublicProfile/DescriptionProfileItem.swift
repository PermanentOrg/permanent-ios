//
//  DescriptionProfileItem.swift
//  Permanent
//
//  Created by Lucian Cerbu on 04.01.2022.
//

import Foundation

class DescriptionProfileItem: ProfileItemModel {
    var longDescription: String? {
        get {
            return textData1
        }
        set {
            textData1 = newValue
        }
    }
    
    init() {
        super.init(fieldNameUI: FieldNameUI.description.rawValue)
        self.type = "type.widget.string"
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}

