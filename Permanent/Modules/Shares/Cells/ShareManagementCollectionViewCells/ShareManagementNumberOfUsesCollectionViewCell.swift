//
//  ShareManagementNumberOfUsesCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 15.11.2022.
//

import UIKit

class ShareManagementNumberOfUsesCollectionViewCell: UICollectionViewCell {
    static let identifier = "ShareManagementNumberOfUsesCollectionViewCell"
    
    @IBOutlet weak var maxUsesLabel: UITextField!
    @IBOutlet weak var additionalInformationLabel: UILabel!
    
    var viewModel: ShareLinkViewModel?
    override func awakeFromNib() {
        super.awakeFromNib()
        maxUsesLabel.delegate = self
        
        maxUsesLabel.font = TextFontStyle.style39.font
        maxUsesLabel.textColor = .darkBlue
        maxUsesLabel.backgroundColor = .whiteGray
        maxUsesLabel.keyboardType = .numberPad
        configureUI()
        
        additionalInformationLabel.font = TextFontStyle.style38.font
        additionalInformationLabel.textColor = .middleGray
    }
    
    func configure(viewModel: ShareLinkViewModel) {
        self.viewModel = viewModel
        let placeholder = NSMutableAttributedString(string: "Max number of uses (optional)".localized(), attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkBlue])
        placeholder.addAttributes([NSAttributedString.Key.foregroundColor: UIColor.lightGray], range: (placeholder.string as NSString).range(of: "(optional)".localized()))
        maxUsesLabel.attributedPlaceholder = placeholder
        if let maxUses = viewModel.shareVO?.maxUses, maxUses > 0 {
            maxUsesLabel.text = String(maxUses)
        }
        additionalInformationLabel.text = "The link will disappear after this number of uses has been reached.".localized()
    }
    
    func configureUI() {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: .done, style: .done, target: self, action: #selector(done))
        
        toolbar.setItems([doneButton], animated: false)
        maxUsesLabel.inputAccessoryView = toolbar
    }
    
    func updateNumberOfUses() {
        if let newMaxUses = Int(maxUsesLabel.text ?? ""),
           Int(newMaxUses) > 0 {
            viewModel?.updateLinkWithChangedField(maxUses: newMaxUses, then: { [self] _, error in
                if error != nil {
                    if let oldMaxUses = viewModel?.shareVO?.maxUses {
                        maxUsesLabel.text = String(oldMaxUses)
                    } else {
                        maxUsesLabel.text = nil
                    }
                }
            })
        } else {
            viewModel?.updateLinkWithChangedField(maxUses: .zero, then: { _, error in
                if error != nil {
                    self.maxUsesLabel.text = String(self.viewModel?.shareVO?.maxUses ?? 0)
                } else {
                    self.maxUsesLabel.text = nil
                }
            })
        }
    }
    
    @objc private func done() {
        self.endEditing(true)
        updateNumberOfUses()
    }
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
}

extension ShareManagementNumberOfUsesCollectionViewCell: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateNumberOfUses()
    }
}
