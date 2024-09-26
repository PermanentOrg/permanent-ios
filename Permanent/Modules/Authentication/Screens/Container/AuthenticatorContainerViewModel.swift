//
//  AuthenticatorContainerViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 09.09.2024.

import Foundation
import SwiftUI

class AuthenticatorContainerViewModel: ObservableObject {
    @Published var contentType: AuthContentType = .login
    @Published var firstViewContentType: AuthContentType = .login
    @Published var isLoading: Bool = false
    var username: String = ""
    var password: String = ""
    var mfaSession: MFASession?
}

enum AuthContentType {
    case login
    case verifyIdentity
    case none
}
