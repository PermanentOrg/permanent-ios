//
//  AuthTextField.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 15.12.2022.
//

import UIKit

@IBDesignable
class AuthTextField: CustomTextField {
    var placeholderEdgeInsets: UIEdgeInsets = .zero
    var contentEdgeInsets: UIEdgeInsets = .zero
    
    @IBInspectable
    var placeholderColor: UIColor = .white.withAlphaComponent(0.5)
    
    @IBInspectable
    var placeholderFont: UIFont = Text.style30.font
    
    let border = CALayer()
    
    private var _authPlaceholder: String? = nil
    override var placeholder: String? {
        set {
            let _prev = _authPlaceholder
            _authPlaceholder = newValue
            
            if _prev == nil {
                setupPlaceholder()
            }
        }
        
        get {
            return nil
        }
    }
    
    override func setup() {
        placeholderEdgeInsets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        contentEdgeInsets = UIEdgeInsets(top: 8, left: 95, bottom: 8, right: 10)
        
        backgroundColor = .white.withAlphaComponent(0.04)
        textColor = .white
        font = Text.style4.font
        tintColor = .white
    }
    
    func setupPlaceholder() {
        let placeholderLabel = UILabel()
        placeholderLabel.font = placeholderFont
        placeholderLabel.text = _authPlaceholder
        placeholderLabel.textColor = placeholderColor
        placeholderLabel.sizeToFit()
        
        leftView = placeholderLabel
        leftViewMode = .always
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: contentEdgeInsets)
    }
    
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: placeholderEdgeInsets)
    }
    
    override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(x: 16, y: 12, width: 95, height: 24)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: contentEdgeInsets)
    }
    
    func addBottomBorder() {
        border.backgroundColor = UIColor.white.withAlphaComponent(0.24).cgColor
        border.frame = CGRect(x: 0, y: frame.size.height - 1.0 / UIScreen.main.scale, width: frame.size.width, height: 1.0 / UIScreen.main.scale)
        layer.addSublayer(border)
    }
    
    func removeBottomBorder() {
        border.removeFromSuperlayer()
    }
    
    override func becomeFirstResponder() -> Bool {
        let ret = super.becomeFirstResponder()
        
        if ret {
            addBottomBorder()
        }
        
        return ret
    }
    
    override func resignFirstResponder() -> Bool {
        let ret = super.resignFirstResponder()
        
        if ret {
            removeBottomBorder()
        }
        
        return ret
    }
}
