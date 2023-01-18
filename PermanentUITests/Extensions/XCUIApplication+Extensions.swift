//
//  XCUIApplication+Extensions.swift
//  PermanentUITests
//
//  Created by Vlad Alexandru Rusu on 15.11.2022.
//

import XCTest

extension XCUIApplication {
    func waitForActivityIndicators() {
        var numberOfSleeps = 0
        while activityIndicators.count > 0 && numberOfSleeps < 60 {
            sleep(1)
            numberOfSleeps += 1
        }
    }
}
