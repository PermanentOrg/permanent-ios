//
//  DashboardRedesign.swift
//  Permanent
//
//  Feature flag for the redesigned dashboard + auth experience.
//  The flag is added to the build settings' Active Compilation Conditions
//  by the project owner; default OFF is correct, so the new screens are not
//  reachable at runtime until the flag is turned on.
//

import Foundation

enum DashboardRedesign {
    static var isEnabled: Bool {
        #if DASHBOARD_REDESIGN
        return true
        #else
        return false
        #endif
    }
}
