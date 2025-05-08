//
//   Colors.swift
//   Permanent
//
//   Created by Adrian Creteanu on 23.11.2020.
//

import UIKit
import SwiftUI

extension UIColor {
    static var mainPink = UIColor(named: "MainPink") ?? UIColor(red: 232 / 255, green: 68 / 255, blue: 133 / 255, alpha: 1)
    static var darkBlue = UIColor(named: "DarkBlue") ?? UIColor(red: 19 / 255, green: 27 / 255, blue: 74 / 255, alpha: 1)
    static var lightBlue = UIColor(named: "LightBlue") ?? UIColor(red: 29 / 255, green: 75 / 255, blue: 178 / 255, alpha: 1)
    static var blueGray = UIColor(named: "BlueGray") ?? UIColor(red: 70 / 255, green: 80 / 255, blue: 132 / 255, alpha: 1)
    static var barneyPurple = UIColor(named: "BarneyPurple") ?? UIColor(red: 141 / 255, green: 0 / 255, blue: 133 / 255, alpha: 1)
    static var lightPurple = UIColor(named: "LightPurple") ?? UIColor(red: 231 / 255, green: 212 / 255, blue: 231 / 255, alpha: 1)
    static var deepRed = UIColor(named: "DeepRed") ?? UIColor(red: 161 / 255, green: 0 / 255, blue: 0 / 255, alpha: 1)
    static var paleRed = UIColor(named: "PaleRed") ?? UIColor(red: 255 / 255, green: 61 / 255, blue: 61 / 255, alpha: 1)
    static var tangerine = UIColor(named: "Tangerine") ?? UIColor(red: 255 / 255, green: 153 / 255, blue: 51 / 255, alpha: 1)
    static var dotGreen = UIColor(named: "DotGreen") ?? UIColor(red: 27 / 255, green: 201 / 255, blue: 23 / 255, alpha: 1)
    static var bilbaoGreen = UIColor(named: "BilbaoGreen") ?? UIColor(red: 22 / 255, green: 125 / 255, blue: 20 / 255, alpha: 1)
    static var paleGreen = UIColor(named: "PaleGreen") ?? UIColor(red: 202 / 255, green: 229 / 255, blue: 201 / 255, alpha: 1)
    static var dullGreen = UIColor(named: "DullGreen") ?? UIColor(red: 130 / 255, green: 177 / 255, blue: 95 / 255, alpha: 1)
    static var white = UIColor(named: "White") ?? UIColor(red: 255 / 255, green: 255 / 255, blue: 255 / 255, alpha: 1)
    static var lightGray = UIColor(named: "LightGray") ?? UIColor(red: 180 / 255, green: 180 / 255, blue: 180 / 255, alpha: 1)
    static var middleGray = UIColor(named: "MiddleGray") ?? UIColor(red: 96 / 255, green: 96 / 255, blue: 96 / 255, alpha: 1)
    static var black = UIColor(named: "Black") ?? UIColor(red: 0 / 255, green: 0 / 255, blue: 0 / 255, alpha: 1)
    static var galleryGray = UIColor(named: "GalleryGray") ?? UIColor(red: 235 / 255, green: 235 / 255, blue: 235 / 255, alpha: 1)
    static var brightRed = UIColor(named: "BrightRed") ?? UIColor(red: 175 / 255, green: 0 / 255, blue: 0 / 255, alpha: 1)
    static var doveGray = UIColor(named: "DoveGray") ?? UIColor(red: 112 / 255, green: 112 / 255, blue: 112 / 255, alpha: 1)
    static var dustyGray = UIColor(named: "DustyGray") ?? UIColor(red: 96 / 255, green: 96 / 255, blue: 96 / 255, alpha: 1)
    static var mainPurple = UIColor(named: "MainPurple") ?? UIColor(red: 141 / 255, green: 0 / 255, blue: 133 / 255, alpha: 1)
    static var paleYellow = UIColor(named: "PaleYellow") ?? UIColor(red: 254 / 255, green: 235 / 255, blue: 214 / 255, alpha: 1)
    static var whiteGray = UIColor(named: "WhiteGray") ?? UIColor(red: 244 / 255, green: 246 / 255, blue: 253 / 255, alpha: 1)
    static var lightRed = UIColor(named: "LightRed") ?? UIColor(red: 240 / 255, green: 68 / 255, blue: 56 / 255, alpha: 1)
    static var warning = UIColor(named: "Warning") ?? UIColor(red: 181 / 255, green: 71 / 255, blue: 8 / 255, alpha: 1)
    static var lightWarning = UIColor(named: "LightWarning") ?? UIColor(red: 254 / 255, green: 240 / 255, blue: 199 / 255, alpha: 1)
}

extension UIColor {
    static var primary = UIColor.darkBlue
    static var secondary = UIColor.tangerine
    static var overlay = UIColor.black.withAlphaComponent(0.25)
    static var bgOverlay = UIColor.black.withAlphaComponent(0.6)
    static var destructive = UIColor.brightRed
    static var textPrimary = UIColor.middleGray
    static var iconTintPrimary = UIColor.middleGray
    static var iconTintLight = UIColor.white
}

extension UIColor {
    static var backgroundPrimary: UIColor {
        return UIColor { (traits) -> UIColor in
            // Return one of two colors depending on light or dark mode
            return traits.userInterfaceStyle == .dark ? .white : .white
        }
    }
}

extension Color {
    static var indianSaffron = Color("IndianSaffron")
    static var darkBlue = Color("DarkBlue")
    static var whiteGray = Color("WhiteGray")
    static var galleryGray = Color("GalleryGray")
    static var middleGray = Color("MiddleGray")
    static var paleOrange = Color("PaleOrange")
    static var lightGray = Color("LightGray")
    static var lightRed = Color("LightRed")
    static var error25 = Color(.error25)
    static var error200 = Color(.error200)
    static var fadeGray = Color(.fadeGray)
    static var error500 = Color(.error500)
    static var barneyPurple = Color(.barneyPurple)
    static var liniarBlue = Color(.liniarBlue)
    static var blue25 = Color(.blue25)
    static var blue50 = Color(.blue50)
    static var blue100 = Color(.blue100)
    static var blue200 = Color(.blue200)
    static var blue300 = Color(.blue300)
    static var blue400 = Color(.blue400)
    static var blue700 = Color(.blue700)
    static var blue600 = Color(.blue600)
    static var blue900 = Color(.blue900)
    static var yellow = Color(.yellow)
    static var success25 = Color(.success25)
    static var success200 = Color(.success200)
    static var success500 = Color(.success500)
}

extension Gradient {
    static var purpleYellowGradient = LinearGradient(gradient:
                                                        Gradient(colors: [
                                                            Color(red: 0.5, green: 0, blue: 0.5),
                                                            Color(red: 1, green: 0.6, blue: 0.2)
                                                        ]),
                                                     startPoint: .topLeading,
                                                     endPoint: .bottomTrailing
    )
    
    static var purpleYellowGradient2 = LinearGradient(
        stops: [
            Gradient.Stop(color: Color(red: 0.5, green: 0, blue: 0.5), location: 0.00),
            Gradient.Stop(color: Color(red: 1, green: 0.6, blue: 0.2), location: 1.00),
        ],
        startPoint: UnitPoint(x: 0, y: 0),
        endPoint: UnitPoint(x: 1, y: 1)
    )
    
    static var yellowPurpleGradient = LinearGradient(gradient:
                                                        Gradient(colors: [
                                                            Color(red: 1, green: 0.6, blue: 0.2),
                                                            Color(red: 0.5, green: 0, blue: 0.5)
                                                        ]),
                                                     startPoint: .topLeading,
                                                     endPoint: .bottomTrailing
    )
    
    static var blue25Gradient = LinearGradient(gradient:
                                                        Gradient(colors: [
                                                            Color.blue25,
                                                            Color.blue25
                                                        ]),
                                                     startPoint: .topLeading,
                                                     endPoint: .bottomTrailing
    )
    
    static var whiteGradient = LinearGradient(gradient:
                                                        Gradient(colors: [
                                                            Color.white,
                                                            Color.white
                                                        ]),
                                                     startPoint: .topLeading,
                                              endPoint: .bottomTrailing
    )
    
    static var darkLightBlueGradient = LinearGradient(stops:
                                                        [
                                                            Gradient.Stop(color: Color(red: 0.07, green: 0.11, blue: 0.29), location: 0.00),
                                                            Gradient.Stop(color: Color(red: 0.21, green: 0.27, blue: 0.57), location: 1.00),
                                                        ],
                                                      startPoint: UnitPoint(x: 0, y: 0),
                                                      endPoint: UnitPoint(x: 1, y: 1)
    )
    
    static var lightDarkPurpleGradient = LinearGradient(stops:
                                                        [
                                                            Gradient.Stop(color: Color(red: 0.5, green: 0, blue: 0.5), location: 0.00),
                                                            Gradient.Stop(color: Color(red: 0.72, green: 0.26, blue: 0.65), location: 1.00),
                                                        ],
                                                      startPoint: UnitPoint(x: 0, y: 0),
                                                      endPoint: UnitPoint(x: 1, y: 1)
    )
    
    static var greenGradient = LinearGradient(gradient:
                                                        Gradient(colors: [
                                                            Color.success500,
                                                            Color.success500
                                                        ]),
                                                     startPoint: .topLeading,
                                              endPoint: .bottomTrailing
    )
}
