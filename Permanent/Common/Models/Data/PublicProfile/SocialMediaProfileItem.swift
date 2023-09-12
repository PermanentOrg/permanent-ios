//
//  SocialMediaProfileItem.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 26.01.2022.
//

class SocialMediaProfileItem: ProfileItemModel {
    var link: String? {
        get {
            return string1
        }
        set {
            string1 = newValue
        }
    }
    
    init() {
        super.init(fieldNameUI: FieldNameUI.socialMedia.rawValue)
        self.type = "type.widget.string"
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}
