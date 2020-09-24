//
//  StringExtension.swift
//  Permanent
//
//  Created by Adrian Creteanu on 21/09/2020.
//  Copyright © 2020 Lucian Cerbu. All rights reserved.
//

import Foundation

extension String {
    var isNotEmpty: Bool {
        return !self.isEmpty
    }
    
    func localized(withComment comment: String = "") -> String {
        return NSLocalizedString(self, comment: comment)
    }
}
