//
//  ScreenLockManager.swift
//  Permanent
//
//  Created by Constantin Georgiu on 11.02.2021.
//

import UIKit.UIApplication

class ScreenLockManager {

    func disableIdleTimer(_ disable: Bool) {
        UIApplication.shared.isIdleTimerDisabled = disable
    }

    deinit {
        UIApplication.shared.isIdleTimerDisabled = false
    }
}
