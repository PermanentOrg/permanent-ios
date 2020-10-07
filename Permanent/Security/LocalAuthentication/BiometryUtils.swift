//
//  BiometryType.swift
//  Permanent
//
//  Created by Adrian Creteanu on 07/10/2020.
//  Copyright © 2020 Victory Square Partners. All rights reserved.
//

import Foundation
import LocalAuthentication.LAContext

struct BiometryUtils {
    static var type: LABiometryType {
        let context = LAContext()
        context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return context.biometryType
    }

    static var biometryName: String {
        switch type {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        default: return ""
        }
    }
}
