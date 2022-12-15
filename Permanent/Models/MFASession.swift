//
//  MFASession.swift
//  Permanent
//
//  Created by Lucian Cerbu on 15.12.2022.
//

import Foundation

class MFASession {
    let twoFactorId: String
    let methodId: String
    
    init(twoFactorId: String, methodId: String) {
        self.twoFactorId = twoFactorId
        self.methodId = methodId
    }
}
