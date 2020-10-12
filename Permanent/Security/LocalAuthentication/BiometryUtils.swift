//
//  BiometryType.swift
//  Permanent
//
//  Created by Adrian Creteanu on 07/10/2020.
//

import Foundation
import LocalAuthentication.LAContext

typealias BiometryInfo = (name: String, iconName: String)

struct BiometryUtils {
    static var type: LABiometryType {
        let context = LAContext()
        context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return context.biometryType
    }

    static var biometryInfo: BiometryInfo {
        switch type {
        case .faceID: return ("Face ID", "faceID")
        case .touchID: return ("Touch ID", "touchID")
        default: return ("", "")
        }
    }

    // TODO: See if we can remove these.
    static var biometryName: String {
        switch type {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        default: return ""
        }
    }

    static var biometryIconName: String {
        switch type {
        case .faceID: return "faceID"
        case .touchID: return "touchID"
        default: return ""
        }
    }
}
