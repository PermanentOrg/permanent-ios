//
//  AuthLeftSideViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 16.09.2024.

import Foundation

class AuthLeftSideViewModel: ObservableObject {
    var containerViewModel: AuthenticatorContainerViewModel
    
    init(containerViewModel: AuthenticatorContainerViewModel) {
        self.containerViewModel = containerViewModel
    }
}
