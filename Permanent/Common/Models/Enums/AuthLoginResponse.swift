//
//  AuthLoginResponse.swift
//  Permanent
//
//  Created by Lucian Cerbu on 25.09.2024.


typealias AuthLoginResponse = (AuthLoginResponseMessage) -> Void

enum AuthLoginResponseMessage {
    case invalidPinCode
    case emptyPinCode
    case error
    case success
    case none
    
    var text: String {
        switch self {
        case .invalidPinCode:
            return "Incorrect pin code."
        case .emptyPinCode:
            return "Empy pin code."
        case .error:
            return .errorMessage
        case .success:
            return ""
        case .none:
            return ""
        }
    }
}
