//
//  UserDefaults.swift
//  Permanent
//
//  Created by Lucian Cerbu on 15/09/2020.
//  Copyright © 2020 Lucian Cerbu. All rights reserved.
//

import Foundation
extension UserDefaults {
    public func optionalBool(forKey defaultName: String) -> Bool? {
        let defaults = self
        if let value = defaults.value(forKey: defaultName) {
            return value as? Bool
        }
        return nil
    }
}
