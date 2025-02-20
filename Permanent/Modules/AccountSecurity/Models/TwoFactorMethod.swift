//
//  TwoStepVerificationView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 02.12.2024.

import Foundation

struct TwoFactorMethod: Identifiable, Equatable {
    var id: String { methodId }
    let methodId: String
    var type: MethodType
    let value: String
    
    enum MethodType: String {
        case email
        case sms
        
        var displayName: String {
            switch self {
            case .email: return "Email"
            case .sms: return "Text message (SMS)"
            }
        }
    }
    
    init(methodId: String, method: String, value: String) {
        self.methodId = methodId
        self.type = MethodType(rawValue: method) ?? .email
        self.value = value
    }
} 
