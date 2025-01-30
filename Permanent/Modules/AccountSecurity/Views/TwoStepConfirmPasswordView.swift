//
//  TwoStepConfirmPasswordView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 17.12.2024.

import SwiftUI

struct TwoStepConfirmPasswordView: View {
    @StateObject var viewModel: TwoStepConfirmPasswordViewModel
    
    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 32) {
                HStack {
                    Text("Enter your Permanent account") +
                    Text(" password ").bold() +
                    Text("to continue adding a two-step verification method.")
                }
                .font(
                    .custom(
                        "Usual-Regular",
                        fixedSize: 14)
                )
                .multilineTextAlignment(.leading)
                .lineSpacing(5)
                .foregroundColor(.blue700)
                VStack(spacing: 16) {
                    CustomPasswordFieldView(password: $viewModel.textFieldPassword) {
                        viewModel.attemptLogin()
                    }
                    RoundButtonUsualFontView(isDisabled: viewModel.textFieldPassword.isEmpty || viewModel.isLoading, isLoading: viewModel.isLoading, text: "Confirm password") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        viewModel.attemptLogin()
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
