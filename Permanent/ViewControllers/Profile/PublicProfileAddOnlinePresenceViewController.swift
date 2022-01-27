//
//  PublicProfileAddOnlinePresenceViewController.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 26.01.2022.
//

import UIKit

class PublicProfileAddOnlinePresenceViewController: BaseViewController<PublicProfilePageViewModel> {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textField: UITextField!
    
    var fieldType: FieldNameUI?
    var profileItem: ProfileItemModel?
    var characterLimit: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationBar()
        initUI()
    }
    
    func setupNavigationBar() {
        styleNavBar()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(closeButtonAction(_:)))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonAction(_:)))
    }
    
    func initUI() {
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.layer.borderWidth = 0.5
        textField.layer.cornerRadius = 3
        textField.textColor = .middleGray
        textField.font = Text.style7.font
        
        titleLabel.textColor = .middleGray
        titleLabel.font = Text.style12.font
        
        if fieldType == .email {
            title = ((profileItem != nil ? "Update" : "Add") + " Email").localized()
            titleLabel.text = "Email".localized()
            
            characterLimit = 80
            
            textField.textContentType = .emailAddress
            textField.text = (profileItem as? EmailProfileItem)?.email
        } else if fieldType == .socialMedia {
            title = ((profileItem != nil ? "Update" : "Add") + " Social Media").localized()
            titleLabel.text = "Social Media".localized()
            
            characterLimit = 120
            
            textField.textContentType = .URL
            textField.text = (profileItem as? SocialMediaProfileItem)?.link
        }
        
        titleLabel.text = (fieldType == .email ? "Email".localized() : "Social Media".localized()) + " (\(textField.text?.count ?? 0)/\(characterLimit))"
    }
    
    @objc func closeButtonAction(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @objc func doneButtonAction(_ sender: Any) {
        showSpinner()
        
        if fieldType == .email {
            let op: ProfileItemOperation = profileItem != nil ? .update : .create
            viewModel?.modifyEmailProfileItem(profileItemId: profileItem?.profileItemId, newValue: textField.text, operationType: op, { success, error, id in
                self.hideSpinner()
                
                if success {
                    self.dismiss(animated: true, completion: nil)
                } else {
                    self.showAlert(title: .error, message: .errorMessage)
                }
            })
        } else if fieldType == .socialMedia {
            let op: ProfileItemOperation = profileItem != nil ? .update : .create
            viewModel?.modifySocialMediaProfileItem(profileItemId: profileItem?.profileItemId, newValue: textField.text, operationType: op, { success, error, id in
                self.hideSpinner()
                
                if success {
                    self.dismiss(animated: true, completion: nil)
                } else {
                    self.showAlert(title: .error, message: .errorMessage)
                }
            })
        }
    }
}

extension PublicProfileAddOnlinePresenceViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let textFieldText = textField.text else { return false }
        
        let textCount = textFieldText.count + string.count - range.length
        
        titleLabel.text = (fieldType == .email ? "Email".localized() : "Social Media".localized()) + " (\(textField.text?.count ?? 0)/\(characterLimit))"
        
        return textCount < characterLimit
    }
}
