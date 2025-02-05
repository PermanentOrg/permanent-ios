//
//  TwoStepChoosePhoneViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 22.01.2025.

import SwiftUI

class TwoStepChoosePhoneViewModel: ObservableObject {
    var containerViewModel: TwoStepConfirmationContainerViewModel
    @Published var formattedPhone: String = ""
    @Published var rawPhone: String = ""
    @Published var isLoading: Bool = false
    
    init(containerViewModel: TwoStepConfirmationContainerViewModel) {
        self.containerViewModel = containerViewModel
    }
    
    func attemptSendCode() {
        let requestPhoneNumber = formattedPhone.replacingOccurrences(of: "+1 ", with: "")
    }
}
