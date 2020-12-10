//  
//  InputSettingsView.swift
//  Permanent
//
//  Created by Adrian Creteanu on 09.12.2020.
//

import UIKit

@IBDesignable
class InputSettingsView: UIView {
    fileprivate var textField: TextField!
    
    fileprivate lazy var datePicker: UIDatePicker = {
       let picker = UIDatePicker()
        picker.datePickerMode = .date
        return picker
    }()
    
    @IBInspectable
    var placeholder: String? {
        didSet {
            textField.placeholder = placeholder
        }
    }
    
    var inputValue: String? {
        return textField.text
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        commonInit()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        textField.frame = bounds
    }
    
    fileprivate func commonInit() {
        layer.borderWidth = 1
        layer.borderColor = UIColor.lightGray.cgColor
        layer.cornerRadius = Constants.Design.actionButtonRadius
        
        textField = TextField()
        textField.placeholderColor = .primary
        textField.placeholderFont = Text.style3.font
        textField.backgroundColor = .backgroundPrimary
        textField.tintColor = .primary
        textField.textColor = .primary
        textField.font = Text.style3.font
        textField.layer.cornerRadius = 0
        
        self.addSubview(textField)
    }
    
    func configureDatePickerUI() {
        let toolbar = UIToolbar();
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneDatePicker));
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: .cancel, style: .plain, target: self, action: #selector(cancelDatePicker));
        
        toolbar.setItems([doneButton,spaceButton,cancelButton], animated: false)
        
        textField.inputView = datePicker
        textField.inputAccessoryView = toolbar
    }
    
    @objc
    private func doneDatePicker(){
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        textField.text = formatter.string(from: datePicker.date)
        self.endEditing(true)
    }

    @objc
    private func cancelDatePicker(){
        self.endEditing(true)
    }
}
