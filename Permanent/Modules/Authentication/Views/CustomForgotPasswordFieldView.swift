//
//  CustomForgotPasswordFieldView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 03.10.2024.

import SwiftUI

struct CustomForgotPasswordFieldView: View {
    @Binding var username: String
    @FocusState var focusedField: LoginFocusField?
    
    var onSubmit: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("", text: $username)
                .textStyle(UsualSmallXRegularTextStyle())
                .placeholder(when: username.isEmpty) {
                    Text("Email address".uppercased())
                        .foregroundColor(.white)
                        .font(.custom("Usual-Regular", size: 10))
                        .kerning(1.6)
                        .lineLimit(1)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 0)
                .frame(height: 56, alignment: .leading)
                .background(.white.opacity(0.04))
                .cornerRadius(12)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .keyboardType(.asciiCapable)
                .textContentType(.emailAddress)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .inset(by: 0.5)
                        .stroke(.white.opacity(0.16), lineWidth: 1)
                )
                .focused($focusedField, equals: .username)
                .submitLabel(.continue)
                .onSubmit {
                    onSubmit()
                }
                .clipShape(.rect(cornerRadius: 4))
                .onTapGesture {
                    focusedField = .username
                }
        }
    }
}
