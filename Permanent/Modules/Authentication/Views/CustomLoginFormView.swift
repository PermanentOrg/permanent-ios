//
//  CustomLoginForm.swift
//  Permanent
//
//  Created by Lucian Cerbu on 12.09.2024.

import SwiftUI

enum LoginFocusField: Hashable {
    case username, password
}

struct CustomLoginFormView: View {
    @Binding var username: String
    @Binding var password: String
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
                .textContentType(.emailAddress)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .inset(by: 0.5)
                        .stroke(.white.opacity(0.16), lineWidth: 1)
                )
                .focused($focusedField, equals: .username)
                .submitLabel(.next)
                .onSubmit {
                    focusedField = .password
                }
                .clipShape(.rect(cornerRadius: 4))
                .onTapGesture {
                    focusedField = .username
                }
            
            SecureField("", text: $password)
                .font(.custom("Usual-Regular", size: 14))
                .foregroundColor(.white)
                .placeholder(when: password.isEmpty) {
                    Text("Password".uppercased())
                        .font(.custom("Usual", size: 10))
                        .kerning(1.6)
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 0)
                .textContentType(.password)
                .frame(height: 56, alignment: .leading)
                .background(.white.opacity(0.04))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .inset(by: 0.5)
                        .stroke(.white.opacity(0.16), lineWidth: 1)
                )
                .focused($focusedField, equals: .password)
                .submitLabel(.continue)
                .onSubmit {
                    onSubmit()
                }
                .clipShape(.rect(cornerRadius: 4))
                .onTapGesture {
                    focusedField = .password
                }
        }
    }
}
