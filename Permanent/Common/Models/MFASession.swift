//
//  MFASession.swift
//  Permanent
//
//  Created by Lucian Cerbu on 15.12.2022.
//

import Foundation

class MFASession {
    let email: String
    let methodType: CodeVerificationType
    
    init(email: String, methodType: CodeVerificationType) {
        self.email = email
        self.methodType = methodType
    }
}
