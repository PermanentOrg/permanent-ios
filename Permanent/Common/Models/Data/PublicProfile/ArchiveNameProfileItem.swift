//
//  ArchiveNameProfileItem.swift
//  Permanent
//
//  Created by Lucian Cerbu on 04.06.2025.
import Foundation

class ArchiveNameProfileItem: ProfileItemModel {
    var archiveName: String? {
        get {
            return string1
        }
        set {
            string1 = newValue
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
