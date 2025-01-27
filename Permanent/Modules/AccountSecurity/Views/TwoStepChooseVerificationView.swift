//
//  TwoStepChooseVerificationView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 22.01.2025.

import SwiftUI

struct TwoStepChooseVerificationView: View {
    @StateObject var viewModel: TwoStepChooseVerificationViewModel
    
    var body: some View {
        VStack {
        }
    }
}

#Preview {
    TwoStepChooseVerificationView(viewModel: 
                                    TwoStepChooseVerificationViewModel(containerViewModel: TwoStepConfirmationContainerViewModel()))
}
