//
//  BottomLineTextField.swift
//  Permanent
//
//  Created by Gabi Tiplea on 18/08/2020.
//  Copyright © 2020 Lucian Cerbu. All rights reserved.
//

import UIKit

@IBDesignable
class TextField: CustomTextField {
    var contentEdgeInsets: UIEdgeInsets = .zero

    override func setup() {
        contentEdgeInsets = UIEdgeInsets(top: 8,
                                         left: 10,
                                         bottom: 8,
                                         right: 10)

        tintColor = .black
    }

    override func layoutSubviews() {
        super.layoutSubviews()
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
        layer.cornerRadius = 5
        layer.borderWidth = active ? 2 : 0
        layer.borderColor = active ? UIColor.tangerine.cgColor : nil
    }
    
}
