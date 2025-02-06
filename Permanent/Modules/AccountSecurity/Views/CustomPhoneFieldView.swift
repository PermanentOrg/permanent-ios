//
//  CustomPhoneFieldView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 05.02.2025.
import SwiftUI

struct CustomPhoneFieldView: View {
    @Binding var phone: String
    @Binding var rawPhoneNumber: String
    
    var onSubmit: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("", text: $phone, prompt: Text(verbatim: "+1 (123) 456 – 7890").foregroundColor(.blue200))
                .keyboardType(.numberPad)
                .onChange(of: phone) { newValue in
                    // Remove any non-numeric characters and +1 prefix
                    let filtered = newValue.replacingOccurrences(of: "+1 ", with: "")
                        .replacingOccurrences(of: "(", with: "")
                        .replacingOccurrences(of: ")", with: "")
                        .replacingOccurrences(of: " ", with: "")
                        .replacingOccurrences(of: "–", with: "")
                        .filter { "0123456789".contains($0) }

                    let truncated = String(filtered.prefix(10))
                    
                    rawPhoneNumber = truncated
                    
                    var formatted = truncated
                    
                    if formatted.count > 6 {
                        formatted.insert(contentsOf: " – ", at: formatted.index(formatted.startIndex, offsetBy: 6))
                    }
                    if formatted.count > 3 {
                        formatted.insert(contentsOf: ") ", at: formatted.index(formatted.startIndex, offsetBy: 3))
                    }
                    if formatted.count > 0 {
                        formatted.insert("(", at: formatted.startIndex)
                        formatted = "+1 " + formatted
                    }

                    if formatted != phone {
                        phone = formatted
                    }
                }
                .font(.custom("Usual-Regular", size: 14))
                .foregroundColor(.blue900)
                .padding(.horizontal, 12)
                .padding(.vertical, 0)
                .frame(height: 56, alignment: .leading)
                .background(.white.opacity(0.04))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .textContentType(.emailAddress)
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
