//
//  RenameTextField.swift
//  Permanent
//
//  Created by Lucian Cerbu on 03.12.2025.
//

import SwiftUI
import UIKit

struct RenameTextField: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFirstResponder: Bool
    var placeholder: String
    var isReturnKeyEnabled: Bool
    var onSubmit: () -> Void
    var onEmptySubmit: () -> Void
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.font = UIFont(name: "Usual-Regular", size: 14)
        textField.textColor = UIColor(named: "blue900")
        textField.placeholder = placeholder
        textField.returnKeyType = .default
        textField.textAlignment = .left
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.spellCheckingType = .no
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textFieldDidChange(_:)), for: .editingChanged)
        context.coordinator.textField = textField
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        
        context.coordinator.isReturnKeyEnabled = isReturnKeyEnabled
        
        DispatchQueue.main.async {
            if isFirstResponder && !uiView.isFirstResponder {
                uiView.becomeFirstResponder()
            } else if !isFirstResponder && uiView.isFirstResponder {
                uiView.resignFirstResponder()
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: RenameTextField
        weak var textField: UITextField?
        var isReturnKeyEnabled: Bool = false
        
        init(_ parent: RenameTextField) {
            self.parent = parent
            self.isReturnKeyEnabled = parent.isReturnKeyEnabled
        }
        
        @objc func textFieldDidChange(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }
        
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            let trimmedText = (textField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedText.isEmpty && isReturnKeyEnabled {
                parent.onSubmit()
                return true
            }
            parent.onEmptySubmit()
            return false
        }
        
        func textFieldDidBeginEditing(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.parent.isFirstResponder = true
            }
        }
        
        func textFieldDidEndEditing(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.parent.isFirstResponder = false
            }
        }
    }
}
