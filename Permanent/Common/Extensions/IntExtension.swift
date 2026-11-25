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
    /// File size as web shows it: 1024 bytes to a KB and two decimals, "5.61 MB". A whole number has no
    /// decimals, "4 MB". The period is pinned to `en_US_POSIX`, so a comma-locale device can't render "5,61 MB".
    var readableFileSize: String {
        guard self > 0 else { return "" }

        let units = ["bytes", "KB", "MB", "GB", "TB", "PB"]
        var value = Double(self)
        var unitIndex = 0
        while value >= 1024 && unitIndex < units.count - 1 {
            value /= 1024
            unitIndex += 1
        }

        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = unitIndex == 0 ? 0 : 2
        let number = formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
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
