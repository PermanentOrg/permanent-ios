//
//  ChangePasswordView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 24.03.2025.

import SwiftUI

enum ChangePasswordFocusField: Hashable {
    case current, new, confirm
}

struct ChangePasswordView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var viewModel: ChangePasswordViewModel
    @State private var strength: PasswordStrength = .weak
    @State var showPassStrength: Bool = false
    @State var keyboardOpenend: Bool = false
    @State var showEmptySpace: Bool = true
    @State var keyboardHeight: CGFloat = 0
    @FocusState private var focusedField: ChangePasswordFocusField?
    var buttonId: UUID = UUID()
    
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
                            .padding(.bottom, 32)
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
            BottomNotificationWithOverlayView(message: viewModel.bottomBannerMessage, showRightButton: false, isVisible: $viewModel.showBottomBanner)
                .padding(.horizontal, Constants.Design.isPhone ? 32 : 128)
                .padding(.bottom, -32)
        }
    }
    
    var backgroundView: some View {
        Color.whiteGray
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .edgesIgnoringSafeArea(.all)
    }
    
    var contentView: some View {
        ZStack(alignment: .bottom) {
            GeometryReader { geometry in
                ScrollViewReader { scrollView in
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 32) {
                            descriptionView
                                .padding(.top, 32)
                                .id(ChangePasswordFocusField.current)
                            Divider()
                                .background(Color(red: 0.91, green: 0.91, blue: 0.93))
                            VStack(spacing: 24) {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Current password".uppercased())
                                        .foregroundColor(Color(red: 0.35, green: 0.37, blue: 0.5))
                                        .font(.custom("Usual", size: 10))
                                        .kerning(1.6)
                                    CustomPasswordFieldWithPreviewView(password: $viewModel.currentPassword, showPasswordPreviewBtn: .constant(false), submitLabel: .next) {
                                        focusedField = .new
                                    }
                                    .focused($focusedField, equals: .current)
                                }
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("New password".uppercased())
                                        .foregroundColor(Color(red: 0.35, green: 0.37, blue: 0.5))
                                        .font(.custom("Usual", size: 10))
                                        .kerning(1.6)
                                        .id(ChangePasswordFocusField.new)
                                    
                                    VStack(spacing: 8) {
                                        CustomPasswordFieldWithPreviewView(password: $viewModel.newPassword, showPasswordPreviewBtn: .constant(true), submitLabel: .next) {
                                            focusedField = .confirm
                                        }
                                        .id(buttonId)
                                        .focused($focusedField, equals: .new)
                                        if showPassStrength {
                                            VStack(alignment: .leading, spacing: 8) {
                                                
                                                StrengthBar(strength: strength)
                                                Text("Password strength: \(strength.rawValue)")
                                                    .foregroundColor(strength.color)
                                                    .font(.custom("Usual", size: 12))
                                            }
                                            .animation(.easeInOut, value: strength)
                                            .onAppear {
                                                strength = viewModel.evaluatePasswordStrength(viewModel.newPassword)
                                            }
                                            .onChange(of: viewModel.newPassword, perform: { newValue in
                                                strength = viewModel.evaluatePasswordStrength(newValue)
                                            })
                                            .padding(.horizontal, 24)
                                        }

                                    }
                                    .onChange(of: viewModel.newPassword, perform: { newValue in
                                        if newValue.count > 7 {
                                            withAnimation {
                                                showPassStrength = true
                                            }
                                        } else {
                                            withAnimation {
                                                showPassStrength = false
                                            }
                                        }
                                    })
                                }
                                
                                
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Re-type new password".uppercased())
                                        .foregroundColor(Color(red: 0.35, green: 0.37, blue: 0.5))
                                        .font(.custom("Usual", size: 10))
                                        .kerning(1.6)
                                        .id(ChangePasswordFocusField.confirm)
                                    CustomPasswordFieldWithPreviewView(password: $viewModel.confirmPassword, showPasswordPreviewBtn: .constant(true), submitLabel: .done) {
                                        focusedField = nil
                                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                    }
                                    .focused($focusedField, equals: .confirm)
                                }
                                RoundButtonUsualFontView(isDisabled: false, isLoading: viewModel.isLoading, text: "Change Password" ) {
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                    viewModel.verifyPasswordFields()
                                }
                                
                                Spacer()
                                
                                if !showEmptySpace {
                                    Spacer()
                                        .id("changePasswordButton")
                                        .frame(height: keyboardHeight - 64 > 0 ? keyboardHeight - 64 : keyboardHeight)
                                }
                            }
                            .onChange(of: viewModel.confirmPassword) { _ in
                                if focusedField == .confirm {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        withAnimation {
                                            scrollView.scrollTo("changePasswordButton", anchor: .center)
                                        }
                                    }
                                }
                            }
                            .onChange(of: viewModel.newPassword) { _ in
                                if focusedField == .new {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        withAnimation {
                                            scrollView.scrollTo(buttonId, anchor: .top)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .frame(height: geometry.size.height)
                    .onAppear {
                        UIScrollView.appearance().bounces = false
                    }
                    .onDisappear {
                        UIScrollView.appearance().bounces = true
                    }
                }
            }
            .onTapGesture {
                withAnimation {
                    showEmptySpace = true
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
                        
                        if focusedField == .confirm {
                            withAnimation {
                                focusedField = .confirm // Re-trigger the focus to ensure scroll happens
                            }
                        } else if focusedField == .new {
                            withAnimation {
                                focusedField = .new // Re-trigger the focus to ensure scroll happens
                            }
                        }
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidHideNotification)) { event in
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
        .onChange(of: viewModel.bottomBannerMessage, perform: { newValue in
            if newValue != .none {
                if viewModel.showBanner == false {
                    viewModel.displayBannerWithAutoClose()
                }
            } else {
                viewModel.showBottomBanner = false
            }
        })
        .navigationBarTitle("Change password", displayMode: .inline)
    }
    
    var descriptionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            if Constants.Design.isPhone {
                Text("Secure your account".uppercased())
                    .foregroundColor(.blue900)
                    .font(.custom("Usual-Medium", size: 10))
                    .kerning(1.6)
                Text("Enter your current password and set new and strong password to enhance security.")
                    .textStyle(UsualRegularMediumTextStyle())
                    .lineSpacing(4)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.blue900)
            } else {
                Text("Secure your account")
                    .foregroundColor(.blue900)
                    .font(.custom("Usual-Medium", size: 24))
                Text("Enter your current password and set new and strong password to enhance security.")
                    .font(.custom("Usual", size: 14))
                    .lineSpacing(4)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(Color(red: 0.35, green: 0.37, blue: 0.5))
            }
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
}

