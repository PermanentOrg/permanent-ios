//
//  TwoStepChooseVerificationViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 22.01.2025.

import SwiftUI

class TwoStepChooseVerificationViewModel: ObservableObject {
    var containerViewModel: TwoStepConfirmationContainerViewModel
    @Published var isEmailMethodSelected: Bool? = nil
    
    init(containerViewModel: TwoStepConfirmationContainerViewModel, isEmailMethodSelected: Bool?) {
        self.containerViewModel = containerViewModel
        self.isEmailMethodSelected = isEmailMethodSelected
    }
}
