//
//  ActionDialogView.swift
//  Permanent
//
//  Created by Adrian Creteanu on 28/10/2020.
//

import UIKit

class ActionDialogView: UIView {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var dialogView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var cancelButton: RoundedButton!
    @IBOutlet weak var positiveButton: RoundedButton!
    @IBOutlet weak var fieldsStackView: UIStackView!
    @IBOutlet weak var removeButton: UIButton!
    @IBOutlet weak var removeButtonContainer: UIView!
    
    @IBOutlet weak var topStackViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var leadingStackViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var trailingStackViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomStackViewConstraint: NSLayoutConstraint!
    
    private lazy var pickerView = UIPickerView()
    
    private var onDismiss: ButtonAction!
    private var placeholders: [String]?
    private var prefilledValues: [String]?
    private var dropdownValues: [String]?
    private var dialogStyle: ActionDialogStyle = .simple
    private var textFieldKeyboardType: UIKeyboardType = .default
    
    var positiveAction: ButtonAction?
    var removeAction: ButtonAction? {
        didSet {
            if removeAction != nil {
                removeButtonContainer.isHidden = false
                layoutIfNeeded()
            } else {
                removeButtonContainer.isHidden = true
                layoutIfNeeded()
            }
        }
    }
    
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
    
    convenience init(frame: CGRect, style: ActionDialogStyle, title: String?, description: String? = nil, positiveButtonTitle: String?, cancelButtonTitle: String?, positiveButtonColor: UIColor?, cancelButtonColor: UIColor?, placeholders: [String]? = nil, prefilledValues: [String]? = nil, dropdownValues: [String]? = nil, textFieldKeyboardType: UIKeyboardType = .default, onDismiss: @escaping ButtonAction) {
        self.init(frame: frame)
        
        self.onDismiss = onDismiss
        self.dialogStyle = style
        self.placeholders = placeholders
        self.prefilledValues = prefilledValues
        self.dropdownValues = dropdownValues
        self.textFieldKeyboardType = textFieldKeyboardType
        
        commonInit()
        
        titleLabel.text = title
        subtitleLabel.text = description
        positiveButton.setTitle(positiveButtonTitle, for: [])
        cancelButton.setTitle(cancelButtonTitle, for: [])
        
        styleActionButton(cancelButton, color: cancelButtonColor!)
        styleActionButton(positiveButton, color: positiveButtonColor!)

        updateUI(forStyle: dialogStyle)
    }
    
    func commonInit() {
        loadNib()
        setupView(contentView)
        
        adjustUI(forStyle: dialogStyle)
        initUI()
    }
    
    fileprivate func initUI() {
        dialogView.layer.cornerRadius = Constants.Design.sheetCornerRadius
        
        titleLabel.font = TextFontStyle.style3.font
        titleLabel.textColor = .primary
        
        subtitleLabel.font = TextFontStyle.style8.font
        subtitleLabel.textColor = .textPrimary
        
        styleFields()
        
        contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismiss)))
        
        removeButton.setTitle("Remove".localized(), for: .normal)
        removeButton.setFont(TextFontStyle.style11.font)
        removeButton.setTitleColor(.primary, for: .normal)
        removeButtonContainer.isHidden = true
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
            initDropdown()
            
        case .dropdownWithDescription:
            fieldsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
            
            initDropdown()
            
        case .multipleFields:
            subtitleLabel.isHidden = true
            let textField = TextField()
            fieldsStackView.addArrangedSubview(textField)

        case .simpleWithDescription:
            fieldsStackView.isHidden = true
            
        case .updatedSimpleWithDescription:
            fieldsStackView.isHidden = true
        }
    }
    
    fileprivate func initDropdown() {
        pickerView.backgroundColor = .backgroundPrimary
        pickerView.delegate = self
        pickerView.dataSource = self
    
        pickerView.frame = CGRect(
            origin: CGPoint(x: 0, y: self.frame.height - Constants.Design.pickerHeight),
            size: CGSize(width: self.frame.width, height: Constants.Design.pickerHeight)
        )
        
        let dropdownView = DropdownView()
        dropdownView.dropdownAction = { [weak self] in
            guard let self = self else { return }
            
            self.endEditing(true)
            self.addSubview(self.pickerView)
            self.scrollView.setContentOffset(CGPoint(x: 0, y: 100), animated: true)
            
            let dropdownView = self.fieldsStackView.arrangedSubviews.last as? DropdownView
            if self.dropdownValues?.contains(dropdownView?.value ?? "") == false {
                dropdownView?.value = self.dropdownValues?[0]
            }
        }
        
        fieldsStackView.addArrangedSubview(dropdownView)
    }
    
    fileprivate func styleActionButton(_ button: RoundedButton, color: UIColor) {
        button.bgColor = color
        button.layer.cornerRadius = Constants.Design.actionButtonRadius
    }
    
    fileprivate func styleTextField(_ field: TextField, placeholder: String?, fieldValue: String? = nil) {
        field.backgroundColor = .galleryGray
        field.layer.borderColor = UIColor.doveGray.cgColor
        field.tintColor = .dustyGray
        field.textColor = .dustyGray
        field.placeholderColor = .dustyGray
        field.placeholder = placeholder
        field.text = fieldValue
        field.keyboardType = textFieldKeyboardType
        field.delegate = self
    }
    
    fileprivate func styleFields() {
        for (index, field) in fieldsStackView.arrangedSubviews.enumerated() {
            let fieldValue = prefilledValues?[index] ?? ""
            let fieldPlaceholder = placeholders?[index]
            
            if let textField = field as? TextField {
                styleTextField(textField, placeholder: fieldPlaceholder, fieldValue: fieldValue)
            } else {
                if let dropdownView = field as? DropdownView {
                    dropdownView.value = fieldValue.isEmpty ? fieldPlaceholder : fieldValue
                }
            }
        }
        
        // Display the keyboard after showing dialog
        if fieldsStackView.isHidden == false {
            fieldsStackView.arrangedSubviews.first?.becomeFirstResponder()
        }
    }
    
    fileprivate func updateUI(forStyle style: ActionDialogStyle) {
        switch style {
        case .updatedSimpleWithDescription:
            dialogView.shadowToBorder(showShadow: true, onlyBottomShadow: true)
            
            titleLabel.textColor = .paleRed
            titleLabel.font = TextFontStyle.style32.font
            
            subtitleLabel.textColor = .black
            subtitleLabel.font = TextFontStyle.style8.font

            dialogView.layer.cornerRadius = 8
            positiveButton.layer.cornerRadius = 1
            
            cancelButton.bgColor = .whiteGray
            cancelButton.setAttributedTitle(NSAttributedString(string: "Cancel".localized(), attributes: [.font: TextFontStyle.style11.font, .foregroundColor: UIColor.darkBlue]), for: .normal)
            cancelButton.setAttributedTitle(NSAttributedString(string: "Cancel".localized(), attributes: [.font: TextFontStyle.style11.font, .foregroundColor: UIColor.darkBlue]), for: .highlighted)
            cancelButton.layer.cornerRadius = 1
            cancelButton.backgroundColor = .whiteGray
            
            topStackViewConstraint.constant = 32
            leadingStackViewConstraint.constant = 24
            trailingStackViewConstraint.constant = 24
            bottomStackViewConstraint.constant = 24
        default:
            break
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
    
    @IBAction func removeButtonPressed(_ sender: Any) {
        removeAction?()
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
    }
}
