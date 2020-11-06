//
//  ActionDialogView.swift
//  Permanent
//
//  Created by Adrian Creteanu on 28/10/2020.
//

import UIKit

class ActionDialogView: UIView {
    @IBOutlet var contentView: UIView!
    @IBOutlet var dialogView: UIView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var subtitleLabel: UILabel!
    @IBOutlet var cancelButton: RoundedButton!
    @IBOutlet var positiveButton: RoundedButton!
    @IBOutlet var fieldsStackView: UIStackView!
    
    private var placeholder: String?
    private var dialogStyle: ActionDialogStyle = .simple
    
    var positiveAction: ButtonAction?
    
    var fieldsInput: [String]? {
        var inputArray: [String]?
            
        for field in fieldsStackView.arrangedSubviews where (field as? TextField) != nil {
            if inputArray == nil {
                inputArray = [String]()
            }
                
            guard let input = (field as? TextField)?.text else { continue }
                
            inputArray?.append(input)
        }
            
        return inputArray
    }
    
    override func layoutSubviews() {
        styleActionButton(cancelButton, color: .brightRed)
        styleActionButton(positiveButton, color: .primary)
        
        for field in fieldsStackView.arrangedSubviews {
            guard let textField = field as? TextField else { continue }
            
            styleTextField(textField)
        }
    }
    
    convenience init(
        frame: CGRect,
        style: ActionDialogStyle,
        title: String?,
        positiveButtonTitle: String?,
        placeholder: String? = nil
    ) {
        self.init(frame: frame)
        
        self.dialogStyle = style
        self.placeholder = placeholder
        
        commonInit()
        
        titleLabel.text = title
        positiveButton.setTitle(positiveButtonTitle, for: [])
    }
    
    func commonInit() {
        Bundle.main.loadNibNamed(String(describing: ActionDialogView.self), owner: self, options: nil)
        
        addSubview(contentView)
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        initUI()
        adjustUI(forStyle: self.dialogStyle)
    }
    
    fileprivate func initUI() {
        contentView.backgroundColor = UIColor.overlay
        dialogView.layer.cornerRadius = 4
        
        titleLabel.font = Text.style3.font
        titleLabel.textColor = .primary
        cancelButton.setTitle(Translations.cancel, for: [])
    }
    
    fileprivate func adjustUI(forStyle style: ActionDialogStyle) {
        switch style {
        case .simple:
            subtitleLabel.isHidden = true
            fieldsStackView.isHidden = true
            
        case .singleField:
            subtitleLabel.isHidden = true
        
        default:
            break
        }
    }
    
    fileprivate func styleActionButton(_ button: RoundedButton, color: UIColor) {
        button.backgroundColor = color
        button.layer.cornerRadius = Constants.Design.actionButtonRadius
    }
    
    fileprivate func styleTextField(_ field: TextField) {
        field.backgroundColor = .galleryGray
        field.layer.borderColor = UIColor.doveGray.cgColor
        field.tintColor = .dustyGray
        field.textColor = .dustyGray
        field.placeholderColor = .dustyGray
        field.placeholder = self.placeholder
        field.delegate = self
    }
    
    // MARK: - Actions
    
    @IBAction
    func closeButtonAction() {
        dismiss()
    }
    
    @IBAction func positiveButtonAction(_ sender: UIButton) {
        positiveAction?()
    }
    
    func dismiss() {
        removeFromSuperview()
    }
}

extension ActionDialogView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        endEditing(true)
        return false
    }
}
