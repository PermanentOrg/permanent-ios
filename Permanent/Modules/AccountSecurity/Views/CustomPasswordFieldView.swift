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

struct CustomPasswordFieldWithPreviewView: View {
    @Binding var password: String
    @Binding var showPasswordPreviewBtn: Bool
    var onSubmit: () -> Void
    var submitLabel: SubmitLabel
    
    init(password: Binding<String>, showPasswordPreviewBtn: Binding<Bool>, submitLabel: SubmitLabel = .done , onSubmit: @escaping () -> Void) {
        self._password = password
        self._showPasswordPreviewBtn = showPasswordPreviewBtn
        self.onSubmit = onSubmit
        self.submitLabel = submitLabel
    }
    
    var body: some View {
        VStack(spacing: 20) {
            SecureInputView("", text: $password, showPasswordPreviewBtn: $showPasswordPreviewBtn)
                .padding(.horizontal, 12)
                .padding(.vertical, 0)
                .frame(height: 56, alignment: .leading)
                .background(.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .inset(by: 0.5)
                        .stroke(Color.blue100, lineWidth: 1)
                )
                .submitLabel(submitLabel)
                .onSubmit {
                    onSubmit()
                }
                .clipShape(.rect(cornerRadius: 4))
        }
    }
}

struct SecureInputView: View {
    @Binding var showPasswordPreviewBtn: Bool
    @Binding private var text: String
    @State var showPasswordState: Bool = false
    private var title: String
    
    init(_ title: String, text: Binding<String>, showPasswordPreviewBtn: Binding<Bool>) {
        self.title = title
        self._text = text
        self._showPasswordPreviewBtn = showPasswordPreviewBtn
    }
    
    var body: some View {
        ZStack(alignment: .trailing) {
            Group {
                if showPasswordState {
                    TextField(title, text: $text)
                        .font(.custom("Menlo-Regular", size: 14))
                        .foregroundColor(.blue900)
                        .kerning(1.12)
                        .placeholder(when: text.isEmpty) {
                            Text("Password".uppercased())
                                .font(.custom("Usual", size: 10))
                                .kerning(1.6)
                                .foregroundColor(.blue900)
                                .lineLimit(1)
                        }
                        .textContentType(.password)
                } else {
                    SecureField(title, text: $text)
                        .font(.custom("Menlo-Regular", size: 14))
                        .foregroundColor(.blue900)
                        .kerning(1.12)
                        .placeholder(when: text.isEmpty) {
                            Text("Password".uppercased())
                                .font(.custom("Usual", size: 10))
                                .kerning(1.6)
                                .foregroundColor(.blue900)
                                .lineLimit(1)
                        }
                        .textContentType(.password)
                }
            }.padding(.trailing, 32)

            if showPasswordPreviewBtn {
                Button(action: {
                    showPasswordState.toggle()
                }) {
                    Image(self.showPasswordState ? .passwordEyeSlash : .passwordEye)
                        .frame(width: 24, height: 24, alignment: .center)
                        .accentColor(.gray)
                }
            }
        }
    }
}
