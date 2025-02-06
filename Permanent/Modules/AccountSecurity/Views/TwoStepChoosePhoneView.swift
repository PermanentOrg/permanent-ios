//
//  TwoStepChoosePhoneView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 29.01.2025.

import SwiftUI

struct TwoStepChoosePhoneView: View {
    @StateObject var viewModel: TwoStepChoosePhoneViewModel
    
    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 32) {
                Text("Enter your phone number and click the button to send a one-time use code. At this time, we can only accept North American cell phone numbers for SMS.")
                .font(
                    .custom(
                        "Usual-Regular",
                        fixedSize: 14)
                )
                .multilineTextAlignment(.leading)
                .lineSpacing(5)
                .foregroundColor(.blue700)
                VStack(spacing: 16) {
                    CustomPhoneFieldView(phone: $viewModel.formattedPhone, rawPhoneNumber: $viewModel.rawPhone) {
                       viewModel.sendTwoFactorEnableCode()
                    }
                    .disabled(viewModel.phoneAlreadyConfirmed)
                    .opacity(viewModel.phoneAlreadyConfirmed ? 0.5 : 1)
                    RoundButtonUsualFontView(isDisabled: !viewModel.rawPhone.isUSPhoneNumber || viewModel.isLoading || viewModel.remainingTime > 0, isLoading: viewModel.isLoading, text: viewModel.sendCodeButtonTitle) {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        viewModel.sendTwoFactorEnableCode()
                    }
                }
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(32)
        }
        //.navigationBarTitle("Confirm your password", displayMode: .inline)
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}
