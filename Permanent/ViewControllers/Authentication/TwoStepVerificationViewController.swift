//
//  TwoStepVerificationViewController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 29/09/2020.
//

import UIKit

class TwoStepVerificationViewController: BaseViewController<AccountViewModel> {
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var subtitleLabel: UILabel!
    @IBOutlet private var extraInfoLabel: UILabel!
    @IBOutlet private var confirmButton: RoundedButton!
    @IBOutlet private var skipButton: UIButton!
    @IBOutlet private var phoneField: CustomTextField!
    @IBOutlet private var copyrightLabel: UILabel!
    
    var signUpCredentials: SignUpCredentials?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // TODO: Move this to base delegate
        initUI()
    }
    
    fileprivate func initUI() {
        view.backgroundColor = .primary
        
        viewModel = AccountViewModel()
        
        titleLabel.text = Translations.twoStepTitle
        titleLabel.textColor = .white
        titleLabel.font = Text.style.font
        
        subtitleLabel.text = Translations.twoStepSubtitle
        subtitleLabel.textColor = .white
        subtitleLabel.font = Text.style2.font
        
        extraInfoLabel.text = Translations.addLater
        extraInfoLabel.textColor = .lightGray
        extraInfoLabel.font = Text.style6.font
        
        confirmButton.setTitle(Translations.submit, for: [])
    
        skipButton.setTitle(Translations.skip, for: [])
        skipButton.setFont(Text.style9.font)
        skipButton.setTitleColor(.white, for: [])
        
        copyrightLabel.text = Translations.copyrightText
        copyrightLabel.textColor = .white
        copyrightLabel.font = Text.style12.font
        
        phoneField.placeholder = "( ___ ) ___ - ____"
        phoneField.delegate = self
    }
    
    // MARK: - Actions
    
    @IBAction func confirmAction(_ sender: RoundedButton) {
        guard
            let phone = phoneField.text,
            phone.isNotEmpty, phone.isPhoneNumber
        else {
            showAlert(title: Translations.error, message: Translations.invalidPhone)
            return
        }
        
        updatePhone()
    }
    
    @IBAction func skipAction(_ sender: UIButton) {
        openMainScreen()
    }
    
    private func openMainScreen() {
        navigationController?.navigate(to: .main, from: .main)
    }
    
    func updatePhone() {
        guard
            let email: String = PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.emailStorageKey),
            let accountID: Int = PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.accountIdStorageKey),
            let csrf: String = PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.csrfStorageKey) else { return }
        
        let updateData = UpdateData(email, phoneField.text!)
        
        showSpinner()
        
        viewModel?.update(for: String(accountID), data: updateData, csrf: csrf, then: { status in
            self.hideSpinner()
            
            switch status {
            case .success:
                DispatchQueue.main.async {
                    self.openMainScreen()
                }
                
            case .error(let message):
                DispatchQueue.main.async {
                    self.showAlert(title: Translations.error, message: message)
                }
            }
        })
    }
}

extension TwoStepVerificationViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        (textField as? TextField)?.toggleBorder(active: true)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        (textField as? TextField)?.toggleBorder(active: false)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }
}
