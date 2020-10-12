//
//  BottomLineTextField.swift
//  Permanent
//
//  Created by Gabi Tiplea on 18/08/2020.
//

import UIKit

@IBDesignable
class TextField: CustomTextField {
    var contentEdgeInsets: UIEdgeInsets = .zero
    
    override var placeholder: String? {
        didSet {
            attributedPlaceholder = NSAttributedString(string: placeholder ?? "",
                                                       attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
        }
    }

    override func setup() {
        contentEdgeInsets = UIEdgeInsets(top: 8,
                                         left: 10,
                                         bottom: 8,
                                         right: 10)

        backgroundColor = .primary
        textColor = .white
        font = Text.style4.font
        tintColor = .white

        layer.cornerRadius = 10
        layer.borderWidth = 1
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
