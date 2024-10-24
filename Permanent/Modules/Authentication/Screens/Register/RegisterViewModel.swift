//
//  RegisterViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 18.10.2024.

import SwiftUI

class RegisterViewModel: ObservableObject {
    @Published var fullname: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var loginStatus: LoginStatus?
    @Published var agreeUpdates: Bool = false
    @Published var agreeTermsAndConditions: Bool = false
    
    var containerViewModel: AuthenticatorContainerViewModel
    
    init(containerViewModel: AuthenticatorContainerViewModel) {
        self.containerViewModel = containerViewModel
    }
}
