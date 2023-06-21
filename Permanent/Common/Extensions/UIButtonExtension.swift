//
//  UIButtonExtension.swift
//  Permanent
//
//  Created by Adrian Creteanu on 17/09/2020.
//

import UIKit.UIButton

extension UIButton {
    func setFont(_ font: UIFont) {
        titleLabel?.font = font
    }
}

class BigAreaButton: UIButton {
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return bounds.insetBy(dx: -20, dy: -10).contains(point)
    }
}
