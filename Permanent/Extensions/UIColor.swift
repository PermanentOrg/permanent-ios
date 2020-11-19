//
//  UIColor.swift
//  Permanent
//
//  Created by Lucian Cerbu on 20/07/2020.
//
import UIKit

// MARK: - Color Parts

extension UIColor {
    static var mainPink = UIColor(red: 232/255, green: 68/255, blue: 133/255, alpha: 1)
    static var darkBlue = UIColor(red: 19/255, green: 27/255, blue: 74/255, alpha: 1)
    static var lightBlue = UIColor(red: 29/255, green: 75/255, blue: 178/255, alpha: 1)
    static var blueGray = UIColor(red: 70/255, green: 80/255, blue: 132/255, alpha: 1)
    static var barneyPurple = UIColor(red: 128/255, green: 0/255, blue: 128/255, alpha: 1)
    static var deepRed = UIColor(red: 161/255, green: 0/255, blue: 0/255, alpha: 1)
    static var tangerine = UIColor(red: 255/255, green: 153/255, blue: 51/255, alpha: 1)
    static var dotGreen = UIColor(red: 27/255, green: 201/255, blue: 23/255, alpha: 1)
    static var green = UIColor(red: 22/255, green: 125/255, blue: 20/255, alpha: 1)
    static var paleGreen = UIColor(red: 202/255, green: 229/255, blue: 201/255, alpha: 1)
    static var dullGreen = UIColor(red: 130/255, green: 177/255, blue: 95/255, alpha: 1)
    static var white = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1)
    static var lightGray = UIColor(red: 180/255, green: 180/255, blue: 180/255, alpha: 1)
    static var middleGray = UIColor(red: 96/255, green: 96/255, blue: 96/255, alpha: 1)
    static var black = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 1)
    static var galleryGray = UIColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1)
    static var brightRed = UIColor(red: 175/255, green: 0/255, blue: 0/255, alpha: 1)
    static var doveGray = UIColor(red: 112/255, green: 112/255, blue: 112/255, alpha: 1)
    static var dustyGray = UIColor(red: 96/255, green: 96/255, blue: 96/255, alpha: 1)
}

extension UIColor {
    static var primary = UIColor.darkBlue
    static var secondary = UIColor.tangerine
    static var backgroundPrimary = UIColor.white
    static var overlay = UIColor.black.withAlphaComponent(0.25)
    static var destructive = UIColor.brightRed
}

extension UIColor {
    
    func lighter(_ color: UIColor, by percentage: CGFloat = 30.0) -> UIColor? {
        return color.adjust(by: abs(percentage))
    }
    

    func lighter(by percentage: CGFloat = 30.0) -> UIColor? {
        return self.adjust(by: abs(percentage))
    }

    func darker(by percentage: CGFloat = 30.0) -> UIColor? {
        return self.adjust(by: -1 * abs(percentage))
    }

    func adjust(by percentage: CGFloat = 30.0) -> UIColor? {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        if self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return UIColor(red: min(red + percentage/100, 1.0),
                           green: min(green + percentage/100, 1.0),
                           blue: min(blue + percentage/100, 1.0),
                           alpha: alpha)
        } else {
            return nil
        }
    }
}
