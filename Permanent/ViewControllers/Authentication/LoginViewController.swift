//
//  LoginViewController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 17/09/2020.
//

import UIKit

class LoginViewController: BaseViewController<AuthViewModel> {
    @IBOutlet private var scrollView: UIScrollView!
    @IBOutlet private var loginLabel: UILabel!
    @IBOutlet private var copyrightLabel: UILabel!
    @IBOutlet private var loginButton: RoundedButton!
    @IBOutlet private var forgotPasswordButton: UIButton!
    @IBOutlet private var signUpButton: UIButton!
    @IBOutlet private var emailField: CustomTextField!
    @IBOutlet private var passwordField: CustomTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initUI()
    }
    
    fileprivate func initUI() {
        view.backgroundColor = .darkBlue
        
        viewModel = AuthViewModel()
        
        loginLabel.text = Translations.login
        loginLabel.textColor = .white
        loginLabel.font = Text.style.font
        
        emailField.placeholder = Translations.email
        passwordField.placeholder = Translations.password
        
        signUpButton.setTitle(Translations.signup, for: [])
        signUpButton.setFont(Text.style5.font)
        signUpButton.setTitleColor(.white, for: [])
        
        forgotPasswordButton.setTitle(Translations.forgotPassword, for: [])
        forgotPasswordButton.setFont(Text.style5.font)
        forgotPasswordButton.setTitleColor(.white, for: [])
        
        copyrightLabel.text = Translations.copyrightText
        copyrightLabel.textColor = .white
        copyrightLabel.font = Text.style12.font
        
        emailField.delegate = self
        passwordField.delegate = self
    }
    
    // MARK: - Actions
    
    private func attemptLogin() {
        guard
            let email = emailField.text,
            let password = passwordField.text,
            email.isNotEmpty, password.isNotEmpty
        else {
            showAlert(title: Translations.error, message: Translations.invalidFields)
            return
        }
        
        let credentials = LoginCredentials(email, password)
        
        showSpinner(colored: .white)
        closeKeyboard()
        
        viewModel?.login(with: credentials, then: { status in
            DispatchQueue.main.async {
                self.handleLoginStatus(status, credentials: credentials)
            }
        })
    }
    
    @IBAction
    func loginAction(_ sender: RoundedButton) {
        attemptLogin()
    }
    
    @IBAction
    func signUpAction(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction
    func forgotPasswordAction(_ sender: UIButton) {
        let alertController = viewModel?.createEmailInputAlert(then: { email, status in
            DispatchQueue.main.async {
                self.handleForgotPasswordStatus(status, email: email)
            }
        })
        
        guard let alert = alertController else { return }
        
        present(alert, animated: true)
    }
    
    fileprivate func handleForgotPasswordStatus(_ status: RequestStatus, email: String?) {
        switch status {
        case .success:
            showAlert(title: Translations.success,
                      message: String(format: Translations.emailSent, email!))
        case .error(let message):
            showAlert(title: Translations.error, message: message)
        }
    }
    
    fileprivate func handleLoginStatus(_ status: LoginStatus, credentials: LoginCredentials) {
        hideSpinner()
        
        switch status {
        case .success:
            navigationController?.navigate(to: .main, from: .main)
        case .mfaToken:
            PreferencesManager.shared.set(credentials.email, forKey: Constants.Keys.StorageKeys.emailStorageKey)
            navigationController?.navigate(to: .verificationCode, from: .authentication)
        case .error(let message):
            showAlert(title: Translations.error, message: message)
        }
    }
}

extension LoginViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        (textField as? TextField)?.toggleBorder(active: true)
    
        let point = CGPoint(x: 0, y: textField.frame.origin.y - 10)
        scrollView.setContentOffset(point, animated: true)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        (textField as? TextField)?.toggleBorder(active: false)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            passwordField.becomeFirstResponder()
            return true
        } else {
            view.endEditing(true)
            scrollView.setContentOffset(.zero, animated: true)
            attemptLogin()
            return false
        }
    }
}
