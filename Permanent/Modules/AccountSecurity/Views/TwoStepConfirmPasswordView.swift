//
//  TwoStepConfirmPasswordView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 17.12.2024.

import SwiftUI

struct TwoStepConfirmPasswordView: View {
    @StateObject private var viewModel: TwoStepConfirmPasswordViewModel
    
    init(viewModel: TwoStepConfirmPasswordViewModel) {
        _viewModel = StateObject(wrappedValue: TwoStepConfirmPasswordViewModel())
    }
    
    var body: some View {
        SimpleCustomNavigationView(content: {
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
                            
                        }
                        RoundButtonUsualFontView(isDisabled: !viewModel.textFieldPassword.isEmpty, isLoading: false, text: "Confirm password") {
                            
                        }
                    }
                    Spacer()
                }
                .padding(32)
            }
            .navigationBarTitle("Confirm your password", displayMode: .inline)
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }, leftButton: {
            EmptyView()
        }, rightButton: {
            EmptyView()
        },
                                   backgroundColor: .white,
                                   textColor: UIColor(Color.blue900),
                                   textStyle: TextFontStyle.style50,
                                   showLeftChevron: false
        )
    }
}
