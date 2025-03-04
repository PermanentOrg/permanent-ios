//
//  CustomPasswordFieldView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 19.12.2024.
import SwiftUI

enum PasswordFocusField: Hashable {
    case isFocused
}

struct CustomPasswordFieldView: View {
    @Binding var password: String
    
    var onSubmit: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            SecureField("", text: $password)
                .font(.custom("Usual-Bold", size: 20))
                .foregroundColor(.blue900)
                .placeholder(when: password.isEmpty) {
                    Text("Password".uppercased())
                        .font(.custom("Usual", size: 10))
                        .kerning(1.6)
                        .foregroundColor(.blue900)
                        .lineLimit(1)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 0)
                .textContentType(.password)
                .frame(height: 56, alignment: .leading)
                .background(.white.opacity(0.04))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .inset(by: 0.5)
                        .stroke(Color.blue100, lineWidth: 1)
                )
                .submitLabel(.done)
                .onSubmit {
                    onSubmit()
                }
                .clipShape(.rect(cornerRadius: 4))
        }
    }
}
