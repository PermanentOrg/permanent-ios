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
    }

    @IBAction func pressedUpdateButton(_ sender: RoundedButton) {
        attemptPasswordChange()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
    
    private func switchBasedNextTextField(_ textField: UITextField) {
        switch textField {
        case self.currentPasswordView:
            self.reTypePasswordView.becomeFirstResponder()
        case self.reTypePasswordView:
            self.newPasswordView.becomeFirstResponder()
        default:
            self.newPasswordView.resignFirstResponder()
        }
    }
    
    // MARK: Actions

    private func attemptPasswordChange() {
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
            let accountID: Int = PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.accountIdStorageKey),
            let csrf: String = PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.csrfStorageKey) else { return }
        
        let updatePasswordParameters = ChangePasswordCredentials(newPass,retypePass,currentPass)
        
        showSpinner(colored: .white)
        closeKeyboard()

//        viewModel?.changePassword(with: String(accountID), data: updatePasswordParameters, csrf: csrf, then: { success in
//            if success {
//                print("Succ")
//            } else {
//                // Display alert error
//                print("Error")
//            }
//        })
//    }
        
        
        viewModel?.changePassword(with: String(accountID), data: updatePasswordParameters, csrf: csrf, then: { status in

            switch status {
            case .success:
                    self.hideSpinner()
                    self.showAlert(title: .success, message: "Password Changed successfully.")
                    print(status)
            case .error(let message):
                DispatchQueue.main.async {
                    self.hideSpinner()
                    self.showAlert(title: .error, message: message)
                }
            case .mfaToken:
                DispatchQueue.main.async {
                    self.hideSpinner()
                    self.showAlert(title: .error, message: "mfa error")
                }
            }
        })
    }
    
    
    fileprivate func handlePasswordChange(_ status: PasswordChangeStatus, credentials: ChangePasswordCredentials) {
        hideSpinner()
        
    }
    
}
extension AccountSettingsViewController : UITextFieldDelegate {
    
}
