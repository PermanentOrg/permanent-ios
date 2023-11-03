//
//  ChipsTextField.swift
//  ChipsApp
//
//  Created by Flaviu Silaghi on 01.11.2023.

import SwiftUI

struct EmailChipsTextField: UIViewRepresentable {
    
    @Binding var text: String
    
    @Binding var isFirstResponder: Bool // false by default
    
    func makeUIView(context: UIViewRepresentableContext<EmailChipsTextField>) -> UITextField {
        let textField = UITextField(frame: .zero)
        textField.delegate = context.coordinator
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: UIViewRepresentableContext<EmailChipsTextField>) {
        uiView.text = text
        uiView.textColor = .darkBlue
        uiView.font = TextFontStyle.style5.font
        uiView.autocapitalizationType = .none
        
        // Manage focus state using coordinator
        if isFirstResponder && context.coordinator.didBecomeFirstResponder != true {
            uiView.becomeFirstResponder()
            context.coordinator.didBecomeFirstResponder = true
            context.coordinator.didResignFirstResponder = false
        } else if !isFirstResponder && context.coordinator.didResignFirstResponder != true {
            uiView.resignFirstResponder()
            context.coordinator.didResignFirstResponder = true
            context.coordinator.didBecomeFirstResponder = false
        }
    }
    
    func makeCoordinator() -> EmailChipsTextField.Coordinator {
        return Coordinator(text: $text, isFirstResponder: $isFirstResponder)
    }
}

extension EmailChipsTextField {
    class Coordinator: NSObject, UITextFieldDelegate {
        var didBecomeFirstResponder: Bool? = nil
        var didResignFirstResponder: Bool? = nil
        
        @Binding var text: String
        @Binding var isFirstResponder: Bool
        
        init(text: Binding<String>, isFirstResponder: Binding<Bool>) {
            _text = text
            _isFirstResponder = isFirstResponder
        }
        
        func textFieldDidBeginEditing(_ textField: UITextField) {
            isFirstResponder = true
        }
        
        func textFieldDidEndEditing(_ textField: UITextField) {
            isFirstResponder = false
        }
        
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            if textField.text == EmailChipView.zwsp {
                textField.text = string
                text = string
                return false
            }
            if let aText = textField.text, let textRange = Range(range, in: text), string != EmailChipView.zwsp {
                text = aText.replacingCharacters(in: textRange, with: string)
            }
            
            return true
        }
    }
}
