//
//  DateTimeDigitsField.swift
//  Permanent
//
//  Created by Lucian Cerbu on 28.10.2026.
//

import SwiftUI
import UIKit

/// One typed field of the date or time box: digits only, as many as the field holds. It selects its digits as it
/// takes the focus, so the next digit replaces them; full or left, it is pulled inside its bounds, and a full one moves on.
struct DateTimeDigitsField: UIViewRepresentable {
    let field: DateTimeEntry.Field
    @Binding var entry: DateTimeEntry
    @Binding var focus: DateTimeEntry.Field?

    /// The look the boxes, their fields and the rows around them share.
    static let font = SwiftUI.Font.custom("Usual-Regular", size: 14, relativeTo: .subheadline)
    static let boxPadding: CGFloat = 16
    static let boxCornerRadius: CGFloat = 12

    func makeUIView(context: Context) -> UITextField {
        let textField = Self.textField(for: field)
        textField.delegate = context.coordinator
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textChanged(_:)), for: .editingChanged)
        return textField
    }

    func updateUIView(_ textField: UITextField, context: Context) {
        context.coordinator.parent = self
        if textField.text != entry[field] {
            textField.text = entry[field]
        }
        let takesFocus = focus == field
        DispatchQueue.main.async {
            if takesFocus, !textField.isFirstResponder {
                textField.becomeFirstResponder()
            } else if !takesFocus, textField.isFirstResponder {
                textField.resignFirstResponder()
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    /// The field as the design draws it: centred digits in the shared font, a pale placeholder, and its name for VoiceOver.
    static func textField(for field: DateTimeEntry.Field) -> UITextField {
        let textField = UITextField()
        let baseFont = UIFont(name: "Usual-Regular", size: 14) ?? .systemFont(ofSize: 14)
        textField.font = UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: baseFont)
        textField.adjustsFontForContentSizeCategory = true
        textField.textColor = .darkBlue
        textField.tintColor = .darkBlue
        textField.textAlignment = .center
        textField.keyboardType = .numberPad
        let placeholderColor = UIColor(named: "Blue200") ?? UIColor(red: 184 / 255, green: 187 / 255, blue: 201 / 255, alpha: 1)
        textField.attributedPlaceholder = NSAttributedString(string: field.placeholder, attributes: [.foregroundColor: placeholderColor])
        textField.accessibilityLabel = field.label
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return textField
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: DateTimeDigitsField

        init(parent: DateTimeDigitsField) {
            self.parent = parent
        }

        /// A tap places the caret after this call, so the digits are selected once the tap is through.
        func textFieldDidBeginEditing(_ textField: UITextField) {
            if parent.focus != parent.field {
                parent.focus = parent.field
            }
            DispatchQueue.main.async { [weak self] in
                guard textField.isFirstResponder else { return }
                self?.selectAll(in: textField)
            }
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            parent.entry.clamp(parent.field)
            textField.text = parent.entry[parent.field]
            if parent.focus == parent.field {
                parent.focus = nil
            }
        }

        /// Only digits, and no more than the field holds; anything else is dropped.
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let current = textField.text ?? ""
            guard let edited = Range(range, in: current) else { return false }
            let typed = current.replacingCharacters(in: edited, with: string)
            return typed.count <= parent.field.limit && typed.allSatisfy { $0.isASCII && $0.isNumber }
        }

        /// Writes the digits to the entry; a field that fills is pulled inside its bounds and passes the focus on.
        @objc func textChanged(_ textField: UITextField) {
            let field = parent.field
            parent.entry[field] = textField.text ?? ""
            guard parent.entry[field].count == field.limit else { return }
            parent.entry.clamp(field)
            textField.text = parent.entry[field]
            if parent.focus == field, let next = field.next {
                parent.focus = next
            }
        }

        func selectAll(in textField: UITextField) {
            textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
        }
    }
}
