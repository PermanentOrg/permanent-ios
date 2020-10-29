//
//  ActionDialogView.swift
//  Permanent
//
//  Created by Adrian Creteanu on 28/10/2020.
//

import UIKit

protocol ActionDialogDelegate: class {
    func didTapPositiveButton()
}

class ActionDialogView: UIView {
    @IBOutlet var contentView: UIView!
    @IBOutlet var dialogView: UIView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var subtitleLabel: UILabel!

    @IBOutlet var cancelButton: RoundedButton!
    @IBOutlet var positiveButton: RoundedButton!
    
    @IBOutlet var fieldsStackView: UIStackView!
    
    private var placeholder: String?
    
    weak var delegate: ActionDialogDelegate?
    
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
        cancelButton.backgroundColor = .brightRed
        cancelButton.layer.cornerRadius = Constants.Design.actionButtonRadius
        
        positiveButton.backgroundColor = .primary
        positiveButton.layer.cornerRadius = Constants.Design.actionButtonRadius
        
        for field in fieldsStackView.arrangedSubviews where (field as? TextField) != nil {
            field.backgroundColor = .galleryGray
            field.layer.borderColor = UIColor.doveGray.cgColor
            
            (field as? TextField)?.tintColor = .dustyGray
            (field as? TextField)?.textColor = .dustyGray
            (field as? TextField)?.placeholderColor = .dustyGray
            (field as? TextField)?.placeholder = self.placeholder
            (field as? TextField)?.delegate = self
        }
    }
    
    convenience init(
        frame: CGRect,
        title: String?,
        positiveButtonTitle: String?,
        placeholder: String? = nil
    ) {
        self.init(frame: frame)
        
        commonInit()
        
        titleLabel.text = title
        positiveButton.setTitle(positiveButtonTitle, for: [])
        
        self.placeholder = placeholder
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        commonInit()
    }
    
    func commonInit() {
        Bundle.main.loadNibNamed(String(describing: ActionDialogView.self), owner: self, options: nil)
        
        addSubview(contentView)
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        initUI()
    }
    
    fileprivate func initUI() {
        contentView.backgroundColor = UIColor.overlay
        
        dialogView.layer.cornerRadius = 4
        
        titleLabel.font = Text.style3.font
        titleLabel.textColor = .primary
        
        cancelButton.setTitle(Translations.cancel, for: [])
        
        // Temporary. This will be decided by the ActionDialogStyle enum.
        subtitleLabel.isHidden = true
    }
    
    // MARK: - Actions
    
    @IBAction
    func closeButtonAction() {
        dismiss()
    }
    
    @IBAction
    func positiveButtonAction() {
        delegate?.didTapPositiveButton()
    }
    
    func dismiss() {
        removeFromSuperview()
    }
}

// enum ActionDialogStyle

extension ActionDialogView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        endEditing(true)
        return false
    }
}
