//
//  AuthTextField.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 15.12.2022.
//

import UIKit

@IBDesignable
class AuthTextField: CustomTextField {
    var contentEdgeInsets: UIEdgeInsets = .zero
    
    @IBInspectable
    var placeholderColor: UIColor = .white.withAlphaComponent(0.5)
    
    @IBInspectable
    var placeholderFont: UIFont = Text.style30.font
    
    override var placeholder: String? {
        didSet {
            attributedPlaceholder = NSAttributedString(string: placeholder ?? "",
                                                       attributes: [
                                                        NSAttributedString.Key.foregroundColor: placeholderColor,
                                                        NSAttributedString.Key.font: placeholderFont
                                                       ])
        }
    }

    override func setup() {
        contentEdgeInsets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)

        backgroundColor = .white.withAlphaComponent(0.04)
        textColor = .white
        font = Text.style4.font
        tintColor = .white

        clipsToBounds = true
        layer.cornerRadius = 0
        layer.borderWidth = 0
        layer.borderColor = UIColor.white.cgColor
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: contentEdgeInsets)
    }

    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: contentEdgeInsets)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: contentEdgeInsets)
    }

    func toggleBorder(active: Bool) {
        layer.borderColor = active ? UIColor.tangerine.cgColor : UIColor.white.cgColor
    }
}

