//
//  ForgotPasswordView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 03.10.2024.

import SwiftUI

struct ForgotPasswordView: View {
    @StateObject var viewModel: ForgotPasswordViewModel
    @State var showEmptySpace: Bool = true
    @FocusState var focusedField: LoginFocusField?
    @State var keyboardOpenend: Bool = false
    @State var keyboardHeight: CGFloat = 0
    
    var loginSuccess: (() -> Void)
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                VStack(spacing: 32) {
                    HStack() {
                        Image(.authLogo)
                            .frame(height: Constants.Design.isPhone ? 32 : 64)
                        Spacer()
                    }
                    HStack() {
                        if Constants.Design.isPhone {
                            Text("Forgot your\npassword?")
                                .font(
                                    .custom(
                                        "Usual-Regular",
                                        size: 32)
                                )
                                .fontWeight(.light)
                                .lineSpacing(8)
                                .foregroundStyle(.white)
                        } else {
                            Text("Forgot your password?")
                                .font(
                                    .custom(
                                        "Usual-Regular",
                                        size: 32)
                                )
                                .fontWeight(.light)
                                .lineSpacing(8)
                                .foregroundStyle(.white)
                        }
                        Spacer()
                    }
                    .layoutPriority(1)
                    HStack {
                        Text("Enter the email address used to sign up for your account to receive instructions on how to reset your password.")
                            .font(
                                .custom("Usual-Regular", size: 14)
                            )
                            .lineSpacing(6)
                            .multilineTextAlignment(.leading)
                            .foregroundColor(.white)
                            .frame(height: 75)
                        Spacer()
                    }
                    .layoutPriority(1)
                    if showEmptySpace {
                        Spacer()
                    }
                    
                    VStack(spacing: 16) {
                        CustomForgotPasswordFieldView(username: $viewModel.email, focusedField: _focusedField) {
                            forgotButtonAction()
                        }
                        RoundButtonRightImageView(text: "Send Request", rightImage: Image(.rightArrowShort), action: {
                            forgotButtonAction()
                        })
                    }
                    HStack(spacing: 20) {
                        Rectangle()
                            .foregroundColor(.clear)
                            .frame(height: 1)
                            .background(Color(red: 0.54, green: 0.55, blue: 0.64))
                            .layoutPriority(0.5)
                        Text("or".uppercased())
                            .font(
                                .custom("Usual-Regular", size: 10))
                            .kerning(1.6)
                            .lineLimit(1)
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color(red: 0.72, green: 0.73, blue: 0.79))
                            .layoutPriority(1)
                        Rectangle()
                            .foregroundColor(.clear)
                            .frame(height: 1)
                            .background(Color(red: 0.54, green: 0.55, blue: 0.64))
                            .layoutPriority(0.5)
                        
                    }
                    SmallRoundButtonImageView(type: .noColor, imagePlace: .onLeft, text: "Back to Sign in", image: Image(.backArrowOnboarding), action: {
                        viewModel.containerViewModel.setContentType(.login)
                    })
                    
                    if !showEmptySpace {
                        Spacer()
                            .layoutPriority(0.5)
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)) { event in
            if let keyboardSize = event.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                keyboardHeight = keyboardSize.size.height
                if keyboardHeight > 120 {
                    if !keyboardOpenend {
                        keyboardOpenend = true
                        withAnimation(.bouncy(duration: 0.3)) {
                            showEmptySpace = false
                        }
                    }
                }
            }
        }.onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidHideNotification)) { event in
            if let keyboardSize = event.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                keyboardHeight = keyboardSize.size.height
                if keyboardHeight > 120 {
                    if keyboardOpenend && self.focusedField == nil{
                        keyboardOpenend = false
                        withAnimation(.bouncy(duration: 0.3)) {
                            showEmptySpace = true
                        }
                    }
                }
            }
        }
        .onTapGesture {
            withAnimation {
                showEmptySpace = true
            }
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func forgotButtonAction() {
        withAnimation {
            showEmptySpace = true
        }
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        viewModel.makeForgotPasswordRequest()
    }
}

#Preview {
    GeometryReader { geometry in
        ZStack {
            Gradient.darkLightBlueGradient
            HStack(spacing: 64) {
                if !Constants.Design.isPhone {
                    AuthLeftSideView(viewModel: AuthLeftSideViewModel(containerViewModel: AuthenticatorContainerViewModel()), startExploringAction: {
                        UIApplication.shared.open(URL(string: "https://www.permanent.org/gallery")!)
                    })
                    .frame(width: geometry.size.width * 0.58)
                    .cornerRadius(12)
                }
                VStack(spacing: 0) {
                    ForgotPasswordView(viewModel: ForgotPasswordViewModel(containerViewModel: AuthenticatorContainerViewModel()), loginSuccess: {
                        
                    })
                    //Spacer()
                }
            }
            .padding(Constants.Design.isPhone ? 32 : 64)
        }
    }
    .ignoresSafeArea(.all)
}
