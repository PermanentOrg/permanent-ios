//
//  TwoStepChooseEmailView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 29.01.2025.

import SwiftUI

struct TwoStepChooseEmailView: View {
    @StateObject var viewModel: TwoStepChooseEmailViewModel
    
    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 32) {
                Text("Enter your email address and click the button to send a one-time use code.")
                .font(
                    .custom(
                        "Usual-Regular",
                        fixedSize: 14)
                )
                .multilineTextAlignment(.leading)
                .lineSpacing(5)
                .foregroundColor(.blue700)
                VStack(spacing: 16) {
                    CustomEmailFieldView(email: $viewModel.textFieldEmail) {
                       // viewModel.attemptLogin()
                    }
                    RoundButtonUsualFontView(isDisabled: !viewModel.textFieldEmail.isValidEmail || viewModel.isLoading, isLoading: viewModel.isLoading, text: "Send code") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        //viewModel.attemptLogin()
                    }
                }
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(32)
        }
        .navigationBarTitle("Confirm your password", displayMode: .inline)
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}
