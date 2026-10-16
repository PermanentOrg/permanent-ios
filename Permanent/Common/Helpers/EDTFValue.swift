//
//  EDTFValue.swift
//  Permanent
//
//  Created by Lucian Cerbu on 14.10.2026.
//

import Foundation

/// What a stored EDTF string decomposes into: a single date, or a range.
enum EDTFValue: Equatable {
    case date(EDTFDateParts)
    case interval(EDTFInterval)
}
