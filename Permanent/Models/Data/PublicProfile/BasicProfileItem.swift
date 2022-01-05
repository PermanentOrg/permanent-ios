//
//  BasicProfileItem.swift
//  Permanent
//
//  Created by Lucian Cerbu on 03.01.2022.
//

import Foundation

class BasicProfileItem: ProfileItemModel {   
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
}
