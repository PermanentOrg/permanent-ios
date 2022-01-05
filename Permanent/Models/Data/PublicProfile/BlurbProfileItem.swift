//
//  BlurbProfileItem.swift
//  Permanent
//
//  Created by Lucian Cerbu on 04.01.2022.
//

import Foundation

class BlurbProfileItem: ProfileItemModel {
    var shortDescription: String? {
        get {
            return string1
        }
        set {
            string1 = newValue
        }
    }
}
