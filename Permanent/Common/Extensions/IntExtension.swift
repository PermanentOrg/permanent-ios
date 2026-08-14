//
//  Int64Extension.swift
//  Permanent
//
//  Created by Lucian Cerbu on 13.03.2023.
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
            transformedSizeInBytes /= 1024
        }

        return useDecimal ? String(format: "%.1f %@", transformedSizeInBytes, unit) : String(format: "%.0f %@", transformedSizeInBytes, unit)
    }
}

extension Int64 {
    /// File size in the app's canonical style — "4 MB", "2.8 MB" — with 1000-based units and a period
    /// separator pinned to `en_US_POSIX`, so a comma-locale device can't render "2,8 MB".
    var readableFileSize: String {
        guard self > 0 else { return "" }

        let units = ["bytes", "KB", "MB", "GB", "TB", "PB"]
        var value = Double(self)
        var unitIndex = 0
        while value >= 1000 && unitIndex < units.count - 1 {
            value /= 1000
            unitIndex += 1
        }

        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = unitIndex == 0 ? 0 : 1
        let number = formatter.string(from: NSNumber(value: value)) ?? String(format: "%.1f", value)
        // ByteCountFormatter emits the singular "1 byte"; preserve that grammar.
        let unit = (unitIndex == 0 && value == 1) ? "byte" : units[unitIndex]
        return "\(number) \(unit)"
    }
}

extension Int64 {
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
        
        if transformedSizeInBytes > 800 {
            unit = unitsOfMeasure[exp]
            transformedSizeInBytes /= 1024
        }
        
        return useDecimal ? String(format: "%.1f %@", transformedSizeInBytes, unit) : String(format: "%.0f %@", transformedSizeInBytes, unit)
    }
}
