//
//  TwoStepChoosePhoneViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 22.01.2025.

import SwiftUI

class TwoStepChoosePhoneViewModel: ObservableObject {
    var containerViewModel: TwoStepConfirmationContainerViewModel
    
    init(containerViewModel: TwoStepConfirmationContainerViewModel) {
        self.containerViewModel = containerViewModel
    }
}
