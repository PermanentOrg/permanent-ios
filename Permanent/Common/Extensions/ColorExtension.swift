//
//  ColorExtension.swift
//  Permanent
//
//  Created by Lucian Cerbu on 25.10.2023.

import SwiftUI

public extension Color {
    init(hexCode: String) {
        let scanner = Scanner(string: hexCode)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let r = (rgbValue & 0xff0000) >> 16
        let g = (rgbValue & 0xff00) >> 8
        let b = rgbValue & 0xff
        
        self.init(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }
}
