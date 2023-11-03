//
//  ChipView.swift
//  ChipsApp
//
//  Created by Flaviu Silaghi on 01.11.2023.

import SwiftUI

struct EmailChipView: View {
    @Binding var chips: [String]
    @State private var inputText = ""
    @State private var isFirstResponder = true
    @State private var errorText: String? = nil
    
    static let zwsp = "\u{200B}"
    
    private static let inputKey: String = UUID().uuidString
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 8, content: {
                HStack {
                    FlowGrid(data: chips,
                             spacing: 8,
                             alignment: .leading,
                             content: { item in
                        VStack {
                            if item == EmailChipView.inputKey {
                                inputField
                                    .frame(minWidth: 150, maxWidth: geometry.size.width)
                            } else {
                                EmailChip(text: item) { text in
                                    chips.removeAll(where: { $0 == text })
                                }
                            }
                        }
                    })
                    .frame(maxWidth: geometry.size.width)
                    .padding(8)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .inset(by: 0.5)
                        .stroke(errorText == nil ? Color(red: 0.91, green: 0.91, blue: 0.93) : .error200, lineWidth: 1)
                )
                .background(Color.white)
                .cornerRadius(8)
                
                if let errorText = errorText {
                    Text("\(errorText) is invalid!")
                        .textStyle(SmallXXXXXItalicTextStyle())
                        .foregroundColor(.lightRed)
                }
            })
            
            
        }
        .onAppear(perform: {
            chips.append(EmailChipView.inputKey)
        })
    }
    
    var inputField: some View {
        VStack {
            EmailChipsTextField(text: $inputText, isFirstResponder: $isFirstResponder)
                .onChange(of: inputText) { _ in
                    if inputText.hasSuffix(" ") || inputText.hasSuffix("\n") || inputText.hasSuffix(",") {
                        let text = String(inputText[..<inputText.index(before: inputText.endIndex)])
                        if text.isValidEmail {
                            chips.insert(String(inputText[..<inputText.index(before: inputText.endIndex)]), at: chips.count - 1)
                            inputText = EmailChipView.zwsp
                            errorText = nil
                        } else {
                            inputText = text
                            errorText = text
                        }
                    } else if chips.count > 1 && inputText.isEmpty {
                        let last = chips.remove(at: chips.count - 2)
                        inputText = last
                    }
                }
                .onChange(of: isFirstResponder) { value in
                    if value == false {
                        chips.insert(inputText.hasPrefix(EmailChipView.zwsp)
                                     ? String(inputText[inputText.index(after: inputText.startIndex)...])
                                     : inputText, at: chips.count - 1)
                        inputText = EmailChipView.zwsp
                    }
                }
        }
    }
}
