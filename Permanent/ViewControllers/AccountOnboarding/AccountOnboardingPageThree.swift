//
//  AccountOnboardingPageThree.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 04.05.2022.
//

import UIKit

class AccountOnboardingPageThree: BaseViewController<AccountOnboardingViewModel> {
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var archiveContainerView: UIView!
    @IBOutlet weak var typeImageView: UIImageView!
    @IBOutlet weak var archiveTitleLabel: UILabel!
    @IBOutlet weak var archiveDetailsLabel: UILabel!
    
    @IBOutlet weak var detailsLabel: UILabel!
    @IBOutlet weak var titleTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.font = TextFontStyle.style.font
        detailsLabel.font = TextFontStyle.style5.font
        
        archiveTitleLabel.font = TextFontStyle.style17.font
        archiveDetailsLabel.font = TextFontStyle.style5.font
        typeImageView.tintColor = .primary
        updateSelectedType()
        
        let leftLabel = UILabel(frame: .zero)
        leftLabel.font = TextFontStyle.style5.font
        leftLabel.text = " The "
        leftLabel.sizeToFit()
        titleTextField.leftView = leftLabel
        titleTextField.leftViewMode = .always
        
        let rightLabel = UILabel(frame: .zero)
        rightLabel.font = TextFontStyle.style5.font
        rightLabel.text = " Archive "
        rightLabel.sizeToFit()
        titleTextField.rightView = rightLabel
        titleTextField.rightViewMode = .always
        
        titleTextField.font = TextFontStyle.style5.font
        
        archiveContainerView.layer.borderColor = UIColor.primary.cgColor
        archiveContainerView.layer.borderWidth = 1
        archiveContainerView.layer.cornerRadius = 5
    }
    
    func updateSelectedType() {
        switch viewModel?.archiveType {
        case .person:
            typeImageView.image = UIImage(named: "archive-person")
            archiveTitleLabel.text = "Person Archive".localized()
            archiveDetailsLabel.text = "represents an individual person, such as yourself or someone else".localized()
            titleTextField.placeholder = "Person Name"
            
        case .family:
            typeImageView.image = UIImage(named: "archive-group")
            archiveTitleLabel.text = "Group Archive".localized()
            archiveDetailsLabel.text = "any group of people, such as a community group or a family".localized()
            titleTextField.placeholder = "Group Name"
            
        case .organization:
            typeImageView.image = UIImage(named: "archive-organization")
            archiveTitleLabel.text = "Organization Archive".localized()
            archiveDetailsLabel.text = "an organizational entity, such as a company or nonprofit".localized()
            titleTextField.placeholder = "Organization Name"
            
        default: break
        }
    }
}

extension AccountOnboardingPageThree: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newString = (textField.text as NSString?)?.replacingCharacters(in: range, with: string)
        viewModel?.archiveName = newString
        
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
