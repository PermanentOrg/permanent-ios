//
//  SmallInputTextWithLabelViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 27.01.2021.
//  Copyright © 2021 Victory Square Partners. All rights reserved.
//

import UIKit

class SmallInputTextWithLabelViewController: UIView {

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
    
    func configureElementUI(label: String, returnKey: UIReturnKeyType = UIReturnKeyType.default) {
        self.contentView.backgroundColor = .white
        self.valueLabel.text = label
        self.valueLabel.font = Text.style8.font
        self.textField.textColor = .middleGray
        self.textField.returnKeyType = returnKey
    }

}
