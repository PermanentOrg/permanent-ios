//
//  PasswordUpdateViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 25.10.2021.
//

import UIKit

class PasswordUpdateViewController: BaseViewController<SecurityViewModel> {
    @IBOutlet var passwordTextField: PasswordElementView!
    @IBOutlet var confirmPasswordTextField: PasswordElementView!
    @IBOutlet var newPasswordTextField: PasswordElementView!
    @IBOutlet var contentUpdateButton: RoundedButton!
    
    @IBOutlet weak var userTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.presentationController?.delegate = self
    
        initUI()
    }
    
    private func initUI() {
        styleNavBar()
        
        title = "Change Password".localized()

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(closeButtonAction(_:)))
        
        contentUpdateButton.configureActionButtonUI(title: "Update password".localized())
        passwordTextField.configurePasswordElementUI(label: .currentPassword, returnKey: UIReturnKeyType.next)
        newPasswordTextField.configurePasswordElementUI(label: .newPassword, returnKey: UIReturnKeyType.next, passFieldContentType: .password)
        confirmPasswordTextField.configurePasswordElementUI(label: .reTypePassword, returnKey: UIReturnKeyType.done, passFieldContentType: .password)
        
        passwordTextField.delegate = self
        confirmPasswordTextField.delegate = self
        newPasswordTextField.delegate = self
        userTextField.delegate = self
        
        userTextField.textContentType = .emailAddress
        
        guard
            let accountEmail: String = AuthenticationManager.shared.session?.account.primaryEmail
        else {
            return
        }
        
        userTextField.text = accountEmail
    }
    // MARK: Actions
    @IBAction func pressedUpdateButton(_ sender: RoundedButton) {
        attemptPasswordChange()
    }
    
    @objc func closeButtonAction(_ sender: Any) {
        
        passwordTextField.passwordTextField.text = nil
        newPasswordTextField.passwordTextField.text = nil
        confirmPasswordTextField.passwordTextField.text = nil
        
        dismiss(animated: true, completion: nil)
    }
    
    private func attemptPasswordChange() {
        guard
            let currentPass = passwordTextField.passwordTextField.text,
            let retypePass = confirmPasswordTextField.passwordTextField.text,
            let newPass = newPasswordTextField.passwordTextField.text,
            currentPass.isNotEmpty, retypePass.isNotEmpty, newPass.isNotEmpty
        else {
            showAlert(title: .error, message: .invalidFields)
            return
        }
        
        guard
            let accountID: Int = AuthenticationManager.shared.session?.account.accountID
        else {
            return
        }
        
        let updatePasswordParameters = ChangePasswordCredentials(newPass, retypePass, currentPass)
        
        showSpinner(colored: .white)
        closeKeyboard()
        
        self.viewModel?.changePassword(with: accountID, data: updatePasswordParameters, then: { status in
            switch status {
            case .success(let message):
                DispatchQueue.main.async {
                    self.hideSpinner()
                    self.dismiss(animated: true, completion: nil)
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

extension PasswordUpdateViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        (textField as? PETextField)?.toggleBorder(active: false)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switchBasedNextTextField(textField)
        return true
    }
    
    private func switchBasedNextTextField(_ textField: UITextField) {
        switch textField {
        case passwordTextField.passwordTextField:
            newPasswordTextField.passwordTextField.becomeFirstResponder()
        case newPasswordTextField.passwordTextField:
            confirmPasswordTextField.passwordTextField.becomeFirstResponder()
        default:
            confirmPasswordTextField.passwordTextField.resignFirstResponder()
        }
    }
}

extension PasswordUpdateViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        passwordTextField.passwordTextField.text = nil
        newPasswordTextField.passwordTextField.text = nil
        confirmPasswordTextField.passwordTextField.text = nil
    }
}
