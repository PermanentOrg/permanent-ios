//
//  AccountSettingsViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 07.01.2021.
//  Copyright © 2021 Victory Square Partners. All rights reserved.
//

import UIKit

class AccountSettingsViewController: BaseViewController<SecurityViewModel> {

    
    
    @IBOutlet weak var contentUpdateButton: RoundedButton!
    @IBOutlet weak var currentPasswordView: PasswordElementView!
    @IBOutlet weak var reTypePasswordView: PasswordElementView!
    @IBOutlet weak var newPasswordView: PasswordElementView!
    @IBOutlet weak var firstLineView: UIView!
    @IBOutlet weak var logWithFaceIdView: SwitchSettingsView!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = SecurityViewModel()
        
        self.title = .security
        view.backgroundColor = .white
        firstLineView.backgroundColor = .lightGray
        logWithFaceIdView.text = .logInWithFingerPrint
        
        contentUpdateButton.configureActionButtonUI(title: .updatePassword)
        
        currentPasswordView.configurePasswordElementUI(label: .currentPassword, returnKey: UIReturnKeyType.next)
        reTypePasswordView.configurePasswordElementUI(label: .reTypePassword, returnKey: UIReturnKeyType.done)
        newPasswordView.configurePasswordElementUI(label: .newPassword , returnKey: UIReturnKeyType.next)
        
        self.currentPasswordView.delegate = self
        self.reTypePasswordView.delegate = self
        self.newPasswordView.delegate = self
        self.logWithFaceIdView.delegate = self

        let authStatus = PermanentLocalAuthentication.instance.canAuthenticate()
        let biometricsAuthEnabled: Bool = PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.biometricsAuthEnabled) ?? true
        
        if (authStatus.error?.statusCode == LocalAuthErrors.localHardwareUnavailableError.statusCode)
        {
            logWithFaceIdView.isUserInteractionEnabled = false
            logWithFaceIdView.toggle(isOn: false)
        } else {
            logWithFaceIdView.toggle(isOn: biometricsAuthEnabled)
        }
    }

    @IBAction func pressedUpdateButton(_ sender: RoundedButton) {
        attemptPasswordChange()
    }
    
    // MARK: Actions

    private func attemptPasswordChange() {
        let group = DispatchGroup()
        
        guard
            let currentPass = currentPasswordView.value,
            let retypePass = reTypePasswordView.value,
            let newPass = newPasswordView.value,
            currentPass.isNotEmpty, retypePass.isNotEmpty,newPass.isNotEmpty
        else {
            showAlert(title: .error, message: .invalidFields)
            return
        }
        
        guard
            let accountID: Int = PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.accountIdStorageKey)
        else {
                return
        }
        
        let updatePasswordParameters = ChangePasswordCredentials(newPass,retypePass,currentPass)
        
        showSpinner(colored: .white)
        closeKeyboard()
        
        group.enter()
        viewModel?.getNewCsrf( then: { status in
            DispatchQueue.main.async {
                group.leave()
            }
        })

        group.notify(queue: DispatchQueue.global()){
            self.viewModel?.changePassword(with: String(accountID), data: updatePasswordParameters, csrf: self.viewModel?.actualCsrf ?? "", then: { status in
            
                switch status {
                case .success(let message):
                    DispatchQueue.main.async {
                        self.hideSpinner()
                        self.currentPasswordView.clearPasswordField()
                        self.reTypePasswordView.clearPasswordField()
                        self.newPasswordView.clearPasswordField()
                        self.showAlert(title: .success, message: message)
                    }
                case .error(let message):
                    DispatchQueue.main.async {
                        self.hideSpinner()
                        self.showAlert(title: .error, message: message)
                    }
                }
            })
        }
    }
    
    func switchToggleWasPressed(Sender: UISwitch) {
        PreferencesManager.shared.set(Sender.isOn,forKey: Constants.Keys.StorageKeys.biometricsAuthEnabled)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.switchBasedNextTextField(textField)
        return true
    }
    
    private func switchBasedNextTextField(_ textField: UITextField) {
        switch textField {
        case self.currentPasswordView.passwordTextField:
            self.newPasswordView.passwordTextField.becomeFirstResponder()
        case self.newPasswordView.passwordTextField:
            self.reTypePasswordView.passwordTextField.becomeFirstResponder()
        default:
            self.reTypePasswordView.passwordTextField.resignFirstResponder()
        }
    }
}
extension AccountSettingsViewController : UITextFieldDelegate {
    
}
extension AccountSettingsViewController : ActionForSwitchSettingsView{
    
}
