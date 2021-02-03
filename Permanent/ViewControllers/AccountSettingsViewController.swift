//
//  AccountSettingsViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 07.01.2021.
//

import UIKit

class AccountSettingsViewController: BaseViewController<SecurityViewModel> {
    @IBOutlet var contentUpdateButton: RoundedButton!
    @IBOutlet var currentPasswordView: PasswordElementView!
    @IBOutlet var reTypePasswordView: PasswordElementView!
    @IBOutlet var newPasswordView: PasswordElementView!
    @IBOutlet var firstLineView: UIView!
    @IBOutlet var logWithBiometricsView: SwitchSettingsView!

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = SecurityViewModel()
        initUI()
    }

    private func initUI() {
        
        title = .security
        view.backgroundColor = .white
        firstLineView.backgroundColor = .lightGray
        logWithBiometricsView.text = viewModel!.getAuthTypeText()
        
        contentUpdateButton.configureActionButtonUI(title: .updatePassword)
        
        currentPasswordView.configurePasswordElementUI(label: .currentPassword, returnKey: UIReturnKeyType.next)
        reTypePasswordView.configurePasswordElementUI(label: .reTypePassword, returnKey: UIReturnKeyType.done)
        newPasswordView.configurePasswordElementUI(label: .newPassword, returnKey: UIReturnKeyType.next)
        
        currentPasswordView.delegate = self
        reTypePasswordView.delegate = self
        newPasswordView.delegate = self
        logWithBiometricsView.delegate = self

        logWithBiometricsView.isUserInteractionEnabled = viewModel!.getUserBiomericsStatus()
        logWithBiometricsView.toggle(isOn: viewModel!.getAuthToggleStatus())
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
            currentPass.isNotEmpty, retypePass.isNotEmpty, newPass.isNotEmpty
        else {
            showAlert(title: .error, message: .invalidFields)
            return
        }
        
        guard
            let accountID: Int = PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.accountIdStorageKey)
        else {
            return
        }
        
        let updatePasswordParameters = ChangePasswordCredentials(newPass, retypePass, currentPass)
        
        showSpinner(colored: .white)
        closeKeyboard()
        
        group.enter()
        viewModel?.getNewCsrf(then: { _ in
            DispatchQueue.main.async {
                group.leave()
            }
        })

        group.notify(queue: DispatchQueue.global()) {
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
    
    func switchToggleWasPressed(sender: UISwitch) {
        PreferencesManager.shared.set(sender.isOn, forKey: Constants.Keys.StorageKeys.biometricsAuthEnabled)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switchBasedNextTextField(textField)
        return true
    }
    
    private func switchBasedNextTextField(_ textField: UITextField) {
        switch textField {
        case currentPasswordView.passwordTextField:
            newPasswordView.passwordTextField.becomeFirstResponder()
        case newPasswordView.passwordTextField:
            reTypePasswordView.passwordTextField.becomeFirstResponder()
        default:
            reTypePasswordView.passwordTextField.resignFirstResponder()
        }
    }
}

extension AccountSettingsViewController: UITextFieldDelegate {}

extension AccountSettingsViewController: ActionForSwitchSettingsView {}
