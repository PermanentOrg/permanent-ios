//
//  RegisterView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 18.10.2024.


import SwiftUI

struct RegisterView: View {
    @StateObject var viewModel: RegisterViewModel
    @State var showEmptySpace: Bool = true
    @FocusState var focusedField: RegisterFocusField?
    @State var keyboardOpenend: Bool = false
    @State var keyboardHeight: CGFloat = 0
    let bottomButtonId = UUID()
    let titleId = UUID()
    let passwordFieldId = UUID()
    let topElementId = UUID()
    
    var loginSuccess: (() -> Void)
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                ScrollViewReader { scrollView in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 32) {
                            if Constants.Design.isPhone {
                                Color.clear
                                    .frame(height: 0)
                            }
                            
                            HStack() {
                                Image(.authLogo)
                                    .frame(height: Constants.Design.isPhone ? 32 : 64)
                                Spacer()
                            }
                            .id(topElementId)
                            HStack() {
                                Text("Create your new account")
                                    .font(
                                        .custom(
                                            "Usual-Regular",
                                            size: 32)
                                    )
                                    .fontWeight(.light)
                                    .lineSpacing(8)
                                    .foregroundStyle(.white)
                                Spacer()
                            }
                            .id(titleId)
                            VStack(spacing: 16) {
                                CustomRegisterFormView(fullname: $viewModel.fullname, email: $viewModel.email, password: $viewModel.password, focusedField: _focusedField) {
                                    withAnimation {
                                        scrollView.scrollTo(bottomButtonId)
                                    }
                                }actionForFirstFieldTap: {
                                    withAnimation {
                                        scrollView.scrollTo(bottomButtonId)
                                    }
                                }actionForLastFieldTap: {
                                    withAnimation {
                                        scrollView.scrollTo(bottomButtonId)
                                    }
                                }
                                .id(passwordFieldId)
                            }
                            
                            HStack(spacing: 0) {
                                Text("I agree to receive updates via email")
                                    .font(
                                        .custom("Usual-Regular", size: 14))
                                    .foregroundColor(Color(red: 0.96, green: 0.96, blue: 0.99))
                                    .frame(maxWidth: .infinity, alignment: .topLeading)
                                    .layoutPriority(1)
                                Spacer()
                                    .layoutPriority(0.5)
                                Toggle(isOn: $viewModel.agreeUpdates, label: {
                                })
                                .fixedSize()
                                .scaleEffect(0.8)
                                .offset(x: 5)
                                .layoutPriority(1)
                                .padding(.trailing, 2)
                            }
                            
                            HStack(spacing: 0) {
                                HStack {
                                    Text("I agree with ")
                                    + Text("[Terms and Conditions](https://www.permanent.org/terms/)")
                                        .underline()
                                }
                                .font(
                                    .custom("Usual-Regular", size: 14))
                                .foregroundColor(Color(red: 0.96, green: 0.96, blue: 0.99))
                                .accentColor(Color(red: 0.96, green: 0.96, blue: 0.99))
                                .frame(maxWidth: .infinity, alignment: .topLeading)
                                .layoutPriority(1)
                                Spacer()
                                    .layoutPriority(0.5)
                                Toggle(isOn: $viewModel.agreeTermsAndConditions, label: {
                                })
                                .fixedSize()
                                .scaleEffect(0.8)
                                .offset(x: 5)
                                .layoutPriority(1)
                                .padding(.trailing, 2)
                            }
                            
                            RoundButtonRightImageView(text: "Sign Up", rightImage: Image(.rightArrowShort), action: {
                                
                            })
                            .opacity(!viewModel.agreeTermsAndConditions ? 0.5 : 1)
                            .disabled(!viewModel.agreeTermsAndConditions)
                            
                            
                            HStack(spacing: 20) {
                                Rectangle()
                                    .foregroundColor(.clear)
                                    .frame(height: 1)
                                    .background(Color(red: 0.54, green: 0.55, blue: 0.64))
                                    .layoutPriority(0.5)
                                Text("Already registered?".uppercased())
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
                            SmallRoundButtonImageView(type: .noColor, imagePlace: .onRight, text: "Sign in", image: Image(.authRegisterKey), action: {
                                self.viewModel.containerViewModel.setContentType(.login)
                            })
                            .id(bottomButtonId)
                            
                            if !showEmptySpace {
                                Spacer()
                                    .frame(height: keyboardHeight - 64 > 0 ? keyboardHeight - 64 : keyboardHeight)
                            }
                            Color.clear
                                .frame(height: 0)
                        }
                    }
                    .frame(height: geometry.size.height - (Constants.Design.isPhone ? 16 : 0))
                    .onAppear {
                        UIScrollView.appearance().bounces = false
                    }
                    .onDisappear {
                        UIScrollView.appearance().bounces = true
                    }
                }
            }
        }
        .onChange(of: viewModel.loginStatus, perform: { status in
        })
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
                keyboardHeight = 0
                    if keyboardSize.height > 120 {
                        if keyboardOpenend {
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func registerAccount() {
        
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
                    .frame(width: geometry.size.width * 0.70)
                    .cornerRadius(12)
                }
                VStack(spacing: 0) {
                    RegisterView(viewModel: RegisterViewModel(containerViewModel: AuthenticatorContainerViewModel()), loginSuccess: {
                        
                    })
                    Spacer()
                }
            }
            .padding(Constants.Design.isPhone ? 32 : 64)
        }
    }
    .ignoresSafeArea(.all)
}
