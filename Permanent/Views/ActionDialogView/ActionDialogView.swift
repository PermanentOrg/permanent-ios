//
//  ActionDialogView.swift
//  Permanent
//
//  Created by Adrian Creteanu on 28/10/2020.
//

import UIKit

class ActionDialogView: UIView {
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var contentView: UIView!
    @IBOutlet var dialogView: UIView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var subtitleLabel: UILabel!
    @IBOutlet var cancelButton: RoundedButton!
    @IBOutlet var positiveButton: RoundedButton!
    @IBOutlet var fieldsStackView: UIStackView!
    
    private lazy var pickerView = UIPickerView()
    
    private var onDismiss: ButtonAction!
    private var placeholders: [String]?
    private var dropdownValues: [String]?
    private var dialogStyle: ActionDialogStyle = .simple
    
    var positiveAction: ButtonAction?
    
    var fieldsInput: [String] {
        var inputArray = [String]()
        
        for element in fieldsStackView.arrangedSubviews {
            if let fieldValue = (element as? TextField)?.text {
                inputArray.append(fieldValue)
            } else if let dropdownValue = (element as? DropdownView)?.value {
                inputArray.append(dropdownValue)
            } else {
                continue
            }
        }
        
        return inputArray
    }
    
    convenience init(
        frame: CGRect,
        style: ActionDialogStyle,
        title: String?,
        positiveButtonTitle: String?,
        placeholders: [String]? = nil,
        dropdownValues: [String]? = nil,
        onDismiss: @escaping ButtonAction
    ) {
        self.init(frame: frame)
        
        self.onDismiss = onDismiss
        self.dialogStyle = style
        self.placeholders = placeholders
        self.dropdownValues = dropdownValues
        
        commonInit()
        
        titleLabel.text = title
        positiveButton.setTitle(positiveButtonTitle, for: [])
    }
    
    func commonInit() {
        loadNib()
        setupView(contentView)
        
        adjustUI(forStyle: dialogStyle)
        initUI()
    }
    
    fileprivate func initUI() {
        dialogView.layer.cornerRadius = Constants.Design.sheetCornerRadius
        
        titleLabel.font = Text.style3.font
        titleLabel.textColor = .primary
        cancelButton.setTitle(.cancel, for: [])
        
        styleActionButton(cancelButton, color: .brightRed)
        styleActionButton(positiveButton, color: .primary)
        
        styleFields()
        
        contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismiss)))
    }
    
    fileprivate func adjustUI(forStyle style: ActionDialogStyle) {
        switch style {
        case .simple:
            subtitleLabel.isHidden = true
            fieldsStackView.isHidden = true
            
        case .singleField:
            subtitleLabel.isHidden = true
            
        case .inputWithDropdown:
            subtitleLabel.isHidden = true
            
            pickerView.backgroundColor = .backgroundPrimary
            pickerView.delegate = self
            pickerView.dataSource = self
        
            pickerView.frame = CGRect(
                origin: CGPoint(x: 0, y: self.frame.height - Constants.Design.pickerHeight),
                size: CGSize(width: self.frame.width, height: Constants.Design.pickerHeight)
            )
            
            let dropdownView = DropdownView()
            dropdownView.dropdownAction = {
                self.endEditing(true)
                self.addSubview(self.pickerView)
                self.scrollView.setContentOffset(CGPoint(x: 0, y: 100), animated: true)
            }
            
            fieldsStackView.addArrangedSubview(dropdownView)
            
        default:
            break
        }
    }
    
    fileprivate func styleActionButton(_ button: RoundedButton, color: UIColor) {
        button.bgColor = color
        button.layer.cornerRadius = Constants.Design.actionButtonRadius
    }
    
    fileprivate func styleTextField(_ field: TextField, placeholder: String?) {
        field.backgroundColor = .galleryGray
        field.layer.borderColor = UIColor.doveGray.cgColor
        field.tintColor = .dustyGray
        field.textColor = .dustyGray
        field.placeholderColor = .dustyGray
        field.placeholder = placeholder
        field.delegate = self
    }
    
    fileprivate func styleFields() {
        for (index, field) in fieldsStackView.arrangedSubviews.enumerated() {
            //guard let textField = field as? TextField else { continue }
            
            if let textField = field as? TextField {
                styleTextField(textField, placeholder: placeholders?[index])
            } else {
                if let dropdownView = field as? DropdownView {
                    dropdownView.value = placeholders?[index]
                }
            }
            
            
        }
        
        // Display the keyboard after showing dialog
        if fieldsStackView.isHidden == false {
            fieldsStackView.arrangedSubviews.first?.becomeFirstResponder()
        }
    }
    
    // MARK: - Actions
    
    @IBAction
    func closeButtonAction() {
        dismiss()
    }
    
    @IBAction func positiveButtonAction(_ sender: UIButton) {
        positiveAction?()
    }
    
    @objc
    func dismiss() {
        onDismiss()
    }
}

extension ActionDialogView: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        scrollView.setContentOffset(CGPoint(x: 0, y: 100), animated: true)
        
        (fieldsStackView.arrangedSubviews.last as? DropdownView)?.rotateImage(upwards: false)
        pickerView.removeFromSuperview()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        scrollView.setContentOffset(.zero, animated: true)
        endEditing(true)
        return false
    }
}

extension ActionDialogView: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return dropdownValues?.count ?? 0
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        guard let values = dropdownValues else {
            return nil
        }
        
        return values[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        let dropdownView = fieldsStackView.arrangedSubviews.last as? DropdownView
        dropdownView?.value = dropdownValues?[row]
        dropdownView?.rotateImage(upwards: false)
        
        scrollView.setContentOffset(.zero, animated: true)
        pickerView.removeFromSuperview()
    }
    
}
