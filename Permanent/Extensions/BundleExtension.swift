//
//  UIApplicationExtension.swift
//  Permanent
//
//  Created by Lucian Cerbu on 21.05.2021.
//
import UIKit

extension Bundle {
    static var release: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }
    static var build: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
    }
}
