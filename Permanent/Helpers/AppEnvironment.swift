//
//  AppEnvironment.swift
//  Permanent
//
//  Created by Lucian Cerbu on 25.04.2023.
//

import Foundation
class AppEnvironment {
    static let shared = AppEnvironment()
    
    private init() { }
    
    func isRunningInAppExtension() -> Bool {
        return Bundle.main.infoDictionary?["NSExtension"] != nil
    }
}
