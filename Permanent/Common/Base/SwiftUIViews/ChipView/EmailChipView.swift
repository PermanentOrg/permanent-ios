//
//  ChipView.swift
//  ChipsApp
//
//  Created by Flaviu Silaghi on 01.11.2023.

import SwiftUI

struct EmailChipView: View {
    @Binding var chips: [String]
    @State private var inputText = ""
    @State private var isFirstResponder = false
    @State private var errorText: String? = nil
    @State private var availableWidth: CGFloat = 10
    
    static let zwsp = "\u{200B}"
    
    private static let inputKey: String = UUID().uuidString
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8, content: {
            ZStack(content: {
                Color.clear
                  .frame(height: 1)
                  .readSize { size in
                    availableWidth = size.width
                  }
            })
            HStack {
                FlowGrid(data: chips,
                         spacing: 8,
                         alignment: .leading,
                         content: { item in
                    VStack {
                        if item == EmailChipView.inputKey {
                            inputField
                                .frame(minWidth: 150, maxWidth: availableWidth)
                        } else {
                            EmailChip(text: item) { text in
                                chips.removeAll(where: { $0 == text })
                            }
                        }
                    }
                })
                .frame(maxWidth: availableWidth, minHeight: 28)
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
        .onAppear(perform: {
            chips.append(EmailChipView.inputKey)
        })
        .onTapGesture {
            if !isFirstResponder && chips.last != EmailChipView.inputKey {
                chips.append(EmailChipView.inputKey)
                isFirstResponder = true
            }
        }
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
                        let text = inputText
                        if text.isValidEmail {
                            chips.insert(text, at: chips.count - 1)
                            inputText = EmailChipView.zwsp
                            errorText = nil
                            chips.removeLast()
                        } else if text.isEmpty || text == EmailChipView.zwsp {
                            inputText = text
                            errorText = nil
                            chips.removeLast()
                        } else {
                            inputText = text
                            errorText = text
                        }
                    }
                }
        }
    }
}
