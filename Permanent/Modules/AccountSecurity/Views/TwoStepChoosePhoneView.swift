//
//  TwoStepChoosePhoneView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 29.01.2025.

import SwiftUI

struct TwoStepChoosePhoneView: View {
    @StateObject var viewModel: TwoStepChoosePhoneViewModel
    @State var keyboardHeight: CGFloat = 0
    @FocusState var codeInputIsFocused: Bool
    let bottomButtonId = UUID()
    let topTextId = UUID()
    
    var body: some View {
        ZStack(alignment: .top) {
            GeometryReader { geometry in
                ScrollViewReader { scrollView in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 32) {
                            HStack {
                                Text("Enter your phone number and click the button to send a one-time use code. At this time, we can only accept ") +
                                Text("North American")
                                    .bold() +
                                Text(" cell phone numbers for SMS.")
                            }
                            .font(
                                .custom(
                                    "Usual-Regular",
                                    fixedSize: 14)
                            )
                            .multilineTextAlignment(.leading)
                            .lineSpacing(5)
                            .foregroundColor(.blue700)
                            .padding(.horizontal, 32)
                            .padding(.top, 32)
                            .id(topTextId)
                            VStack(spacing: 16) {
                                CustomPhoneFieldView(phone: $viewModel.formattedPhone, rawPhoneNumber: $viewModel.rawPhone) {
                                    viewModel.sendTwoFactorEnableCode()
                                }
                                .disabled(viewModel.phoneAlreadyConfirmed)
                                .opacity(viewModel.phoneAlreadyConfirmed ? 0.5 : 1)
                                RoundButtonUsualFontView(isDisabled: !viewModel.rawPhone.isUSPhoneNumber || viewModel.isLoadingPhoneValidation || viewModel.remainingTime > 0, isLoading: viewModel.isLoadingPhoneValidation, text: viewModel.sendCodeButtonTitle) {
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                    viewModel.sendTwoFactorEnableCode()
                                }
                            }
                            .padding(.horizontal, 32)
                            .padding(.bottom, 32)
                        }
                        .frame(maxWidth: .infinity)
                        .safeAreaInset(edge: .bottom) {
                            if viewModel.phoneAlreadyConfirmed {
                                VStack(alignment: .leading, spacing: 32) {
                                    Text("Enter the 4-digit code you received.")
                                        .font(
                                            .custom(
                                                "Usual-Regular",
                                                fixedSize: 14)
                                        )
                                        .multilineTextAlignment(.leading)
                                        .lineSpacing(5)
                                        .foregroundColor(.blue700)
                                        .padding(.top, 32)
                                        .padding(.horizontal, 32)
                                    VStack(spacing: 16) {
                                        Add2FAFieldView(numberOfFields: 4, code: $viewModel.pinCode, digitsDisabled: $viewModel.isLoadingCodeVerification)
                                            .focused($codeInputIsFocused)
                                            .opacity(viewModel.isLoadingCodeVerification ? 0.5 : 1)
                                        RoundButtonUsualFontView(isDisabled: viewModel.pinCode.count != 4, isLoading: viewModel.isLoadingCodeVerification, text: "Enable") {
                                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                            viewModel.verifyAndEnableReceivedTwoFactorEnableCode()
                                            //viewModel.testEnableCode()
                                        }
                                    }
                                    .padding(.horizontal, 32)
                                    Spacer()
                                }
                                .safeAreaInset(edge: .bottom, content: {
                                    Color.blue25
                                        .frame(height: 300)
                                        .id(bottomButtonId)
                                })
                                .background(Color.blue25)
                            } else {
                                Spacer()
                            }
                        }
                    }
                    .frame(minHeight: geometry.size.height)
                    .frame(maxWidth: .infinity)
                    .onAppear {
                        UIScrollView.appearance().bounces = false
                    }
                    .onDisappear {
                        UIScrollView.appearance().bounces = true
                        
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)) { event in
                        if let keyboardSize = event.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                            if codeInputIsFocused {
                                withAnimation {
                                    scrollView.scrollTo(bottomButtonId, anchor: .bottom)
                                }
                            }
                        }
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidHideNotification)) { event in
                        if let keyboardSize = event.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                            if !codeInputIsFocused {
                                withAnimation {
                                    scrollView.scrollTo(topTextId, anchor: .top)
                                }
                            }
                        }
                    }
                }
            }
            .ignoresSafeArea(.all, edges: .bottom)
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

#Preview {
    TwoStepChoosePhoneView(viewModel: TwoStepChoosePhoneViewModel(containerViewModel: TwoStepConfirmationContainerViewModel()))
}
