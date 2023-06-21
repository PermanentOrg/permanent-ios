//
//  Int64Extension.swift
//  Permanent
//
//  Created by Lucian Cerbu on 13.03.2023.
//  Copyright © 2023 Victory Square Partners. All rights reserved.
//

import Foundation

extension Int {
    func bytesToReadableForm(useDecimal: Bool = true) -> String {
        var unit = "B"
        var exp = 0
        var transformedSizeInBytes = Float(self)
        
        let byteSize: Float = 1024
        let unitsOfMeasure = ["KB", "MB", "GB", "TB", "PB"]
        
        if self < Int(byteSize) { return "\(self) \(unit)" }
        
        while transformedSizeInBytes >= byteSize {
            transformedSizeInBytes /= byteSize
            exp += 1
        }
        
        unit = unitsOfMeasure[exp - 1]
        
        if transformedSizeInBytes > 100 {
            unit = unitsOfMeasure[exp]
            transformedSizeInBytes /= 1000
        }
        
        return useDecimal ? String(format: "%.1f %@", transformedSizeInBytes, unit) : String(format: "%.0f %@", transformedSizeInBytes, unit)
    }
}
