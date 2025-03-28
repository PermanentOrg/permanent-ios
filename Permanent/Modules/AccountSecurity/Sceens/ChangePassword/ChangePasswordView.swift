//
//  ChangePasswordView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 24.03.2025.

import SwiftUI

struct ChangePasswordView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var viewModel: ChangePasswordViewModel
    @State private var strength: PasswordStrength = .weak
    
    init() {
        self._viewModel = StateObject(wrappedValue: ChangePasswordViewModel())
    }
    
    var body: some View {
        ZStack {
            if Constants.Design.isPhone {
                CustomNavigationView {
                    ZStack {
                        backgroundView
                        contentView
                            .padding(.vertical, 32)
                            .padding(.horizontal, 32)
                    }
                    .ignoresSafeArea(.all)
                } leftButton: {
                    backButton
                } rightButton: {
                    EmptyView()
                }
            } else {
                ZStack {
                    backgroundView
                    contentView
                        .padding(.vertical, 64)
                        .padding(.horizontal, 128)
                }
                .ignoresSafeArea(.all)
            }
            BottomNotificationWithOverlayView(message: viewModel.bottomBannerMessage, isVisible: $viewModel.showBottomBanner)
                .padding(.horizontal, 32)
        }
    }
    
    var backgroundView: some View {
        Color.whiteGray
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .edgesIgnoringSafeArea(.all)
    }
    
    var contentView: some View {
        ZStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 32) {
                descriptionView
                Divider()
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Current password".uppercased())
                            .foregroundColor(Color(red: 0.35, green: 0.37, blue: 0.5))
                            .font(.custom("Usual", size: 10))
                            .kerning(1.6)
                        CustomPasswordFieldView(password: $viewModel.currentPassword) {
                        }
                    }
                    VStack(alignment: .leading, spacing: 16) {
                        Text("New password".uppercased())
                            .foregroundColor(Color(red: 0.35, green: 0.37, blue: 0.5))
                            .font(.custom("Usual", size: 10))
                            .kerning(1.6)
                        
                        VStack(spacing: 8) {
                            CustomPasswordFieldView(password: $viewModel.newPassword) {
                                
                            }
                            VStack(alignment: .leading, spacing: 8) {
                                
                                StrengthBar(strength: strength)
                                Text("Password strength: \(strength.rawValue)")
                                    .foregroundColor(strength.color)
                                    .font(.custom("Usual", size: 12))
                            }
                            .animation(.easeInOut, value: strength)
                            .onAppear {
                                strength = evaluatePasswordStrength(viewModel.newPassword)
                            }
                            .onChange(of: viewModel.newPassword, perform: { newValue in
                                strength = evaluatePasswordStrength(newValue)
                            })
                            .padding(.horizontal, 24)
                        }
                    }
                    
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Re-type new password".uppercased())
                            .foregroundColor(Color(red: 0.35, green: 0.37, blue: 0.5))
                            .font(.custom("Usual", size: 10))
                            .kerning(1.6)
                        CustomPasswordFieldView(password: $viewModel.confirmPassword) {
                        }
                    }
                    
                    
                    RoundButtonUsualFontView(isDisabled: false, isLoading: false, text: "Change Password" ) {
                    }
                    Spacer()
                }
            }
        }
        .onChange(of: viewModel.bottomBannerMessage, perform: { newValue in
            if newValue != .none {
                if viewModel.showError == false {
                    viewModel.displayBannerWithAutoClose()
                }
            } else {
                viewModel.showBottomBanner = false
            }
        })
        .navigationBarTitle("Change password", displayMode: .inline)
    }
    
    func evaluatePasswordStrength(_ password: String) -> PasswordStrength {
        if password.isEmpty {
            return .weak
        }
        
        let lengthCriteria = password.count >= 8
        let numberCriteria = password.rangeOfCharacter(from: .decimalDigits) != nil
        let uppercaseCriteria = password.rangeOfCharacter(from: .uppercaseLetters) != nil
        let specialCharacterCriteria = password.rangeOfCharacter(from: CharacterSet.punctuationCharacters) != nil
        
        let score = [lengthCriteria, numberCriteria, uppercaseCriteria, specialCharacterCriteria].filter { $0 }.count
        
        switch score {
        case 0...1:
            return .weak
        case 2...3:
            return .medium
        default:
            return .strong
        }
    }
    
    var descriptionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Secure your account".uppercased())
                .foregroundColor(.blue900)
                .font(.custom("Usual-Medium", size: 10))
                .kerning(1.6)
            Text("Enter your current password and set new and strong password to enhance security.")
                .textStyle(UsualRegularMediumTextStyle())
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
                .foregroundColor(.blue900)
        }
    }
    
    var backButton: some View {
        Button(action: {
            dismissView()
        }) {
            HStack {
                Image(.settingsNavigationBarBackIcon)
                    .foregroundColor(.white)
            }
        }
    }
    
    func dismissView() {
        presentationMode.wrappedValue.dismiss()
    }
    
    struct StrengthBar: View {
        var strength: PasswordStrength
        var height: CGFloat = 4
        
        var body: some View {
            GeometryReader { geometry in
                switch strength {
                case .weak:
                    HStack(spacing: 4) {
                        StrenghtBarSegment(color: strength.color, maxWidth: geometry.size.width/3, height: height)
                        ForEach(0..<2) { _ in
                            StrenghtBarSegment(color: Color(red: 0.91, green: 0.91, blue: 0.93), maxWidth: geometry.size.width/3, height: height)
                        }
                    }
                case .medium:
                    HStack(spacing: 4) {
                        ForEach(0..<2) { _ in
                            StrenghtBarSegment(color: strength.color, maxWidth: geometry.size.width/3, height: height)
                        }
                        StrenghtBarSegment(color: Color(red: 0.91, green: 0.91, blue: 0.93), maxWidth: geometry.size.width/3, height: height)
                    }
                case .strong:
                    HStack(spacing: 4) {
                        ForEach(0..<3) { _ in
                            StrenghtBarSegment(color: strength.color, maxWidth: geometry.size.width/3, height: height)
                        }
                    }
                }
            }
            .frame(height: height)
        }
    }

    struct StrenghtBarSegment: View {
        var color: Color
        var maxWidth: CGFloat
        var height: CGFloat = 4
        
        var body: some View {
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(height: height)
                .frame(maxWidth: maxWidth)
        }
    }
    
    enum PasswordStrength: String {
        case weak = "weak"
        case medium = "medium"
        case strong = "strong"
        
        var color: Color {
            switch self {
            case .weak:
                return Color(red: 0.94, green: 0.27, blue: 0.22)
            case .medium:
                return Color(red: 0.97, green: 0.56, blue: 0.03)
            case .strong:
                return Color(red: 0.07, green: 0.72, blue: 0.42)
            }
        }
    }
}

