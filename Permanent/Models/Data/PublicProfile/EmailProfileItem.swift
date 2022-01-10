//
//  EmailProfileItem.swift
//  Permanent
//
//  Created by Lucian Cerbu on 04.01.2022.
//

import Foundation

class EmailProfileItem: ProfileItemModel {
    var emailAddress: String? {
        get {
            return string1
        }
        set {
            string1 = newValue
        }
    }
}
