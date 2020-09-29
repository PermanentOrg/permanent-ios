//
//  VerificationCodeController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 22/09/2020.
//  Copyright © 2020 Lucian Cerbu. All rights reserved.
//

import UIKit

class VerificationCodeController: BaseViewController<VerificationCodeViewModel> {
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var confirmButton: RoundedButton!
    @IBOutlet private var copyrightLabel: UILabel!
    @IBOutlet private var codeField: CustomTextField!
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initUI()
    }
    
    fileprivate func initUI() {
        view.backgroundColor = .darkBlue
        
        viewModel = VerificationCodeViewModel()
        
        titleLabel.text = Translations.enterVerificationCode
        titleLabel.textColor = .white
        titleLabel.font = Text.style.font
        
        copyrightLabel.text = Translations.copyrightText
        copyrightLabel.textColor = .white
        copyrightLabel.font = Text.style12.font
        
        codeField.placeholder = Translations.enterCode
        codeField.delegate = self
        codeField.smartInsertDeleteType = .no
    }
    
    // MARK: - Actions
    
    @IBAction func confirmAction(_ sender: UIButton) {
        guard
            let email: String = PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.emailStorageKey),
            let code = codeField.text,
            code.isNotEmpty else { return }
        
        let credentials = VerifyCodeCredentials(email, code)
        
        viewModel?.verify(for: credentials, then: { status in
            DispatchQueue.main.async {
                self.handleVerifyStatus(status)
            }
        })
    }
    
    fileprivate func handleVerifyStatus(_ status: CodeVerificationStatus) {
        switch status {
        case .success:
            navigationController?.navigate(to: .main, from: .main)
        case .error:
            showAlert(title: Translations.error, message: Translations.errorMessage)
        }
    }
}

extension VerificationCodeController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        (textField as? TextField)?.toggleBorder(active: true)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        (textField as? TextField)?.toggleBorder(active: false)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        let newLength = text.count + string.count - range.length
        
        return newLength <= 4 // TODO: Make a property in TextField for this value
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
