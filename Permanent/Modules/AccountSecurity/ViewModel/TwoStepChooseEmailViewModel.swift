//
//  TwoStepChooseEmailViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 22.01.2025.

import SwiftUI

class TwoStepChooseEmailViewModel: ObservableObject {
    var containerViewModel: TwoStepConfirmationContainerViewModel
    
    init(containerViewModel: TwoStepConfirmationContainerViewModel) {
        self.containerViewModel = containerViewModel
    }
}
