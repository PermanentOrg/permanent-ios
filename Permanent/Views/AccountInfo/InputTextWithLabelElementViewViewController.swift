//
//  InputTextWithLabelElementViewViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 27.01.2021.
//

import UIKit

class InputTextWithLabelElementViewViewController: UIView {

    @IBOutlet var contentView: UIView!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var textField: UITextField!
    
    var value: String? {
        return textField.text
    }
    
    var delegate: UITextFieldDelegate? {
        didSet {
            textField.delegate = delegate
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        commonInit()
    }
    
    fileprivate func commonInit() {
        loadNib()
        setupView(contentView)
        contentView.backgroundColor = .blueGray
    }
    
    func configureElementUI(label: String, returnKey: UIReturnKeyType = UIReturnKeyType.default, keyboardType: UIKeyboardType = .default) {
        self.contentView.backgroundColor = .white
        self.valueLabel.text = label
        self.valueLabel.font = TextFontStyle.style8.font
        self.textField.textColor = .middleGray
        self.textField.returnKeyType = returnKey
        self.textField.autocorrectionType = .no
        if keyboardType != .default {
            self.textField.keyboardType = keyboardType
        }
    }
    
    func setTextFieldValue(text: String)
    {
        self.textField.text = text
    }
}
