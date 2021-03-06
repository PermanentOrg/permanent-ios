//
//  SignUpViewController.swift
//  Permanent
//
//  Created by Gabi Tiplea on 14/08/2020.
//

import UIKit

class SignUpViewController: BaseViewController<AuthViewModel> {
    @IBOutlet private var scrollView: UIScrollView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var copyrightLabel: UILabel!
    @IBOutlet private var loginButton: UIButton!
    @IBOutlet private var signUpButton: RoundedButton!
    @IBOutlet private var nameField: CustomTextField!
    @IBOutlet private var emailField: CustomTextField!
    @IBOutlet private var passwordField: CustomTextField!
    
    fileprivate var areFieldsValid: Bool {
        guard
            nameField.text?.isNotEmpty == true,
            let emailAddress = emailField.text, emailAddress.isNotEmpty, emailAddress.isValidEmail,
            let password = passwordField.text, password.count >= 8
        else {
            return false
        }
             
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .primary
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        viewModel = AuthViewModel()

        titleLabel.text = .signup
        titleLabel.textColor = .white
        titleLabel.font = Text.style.font
        
        nameField.placeholder = .fullName
        emailField.placeholder = .email
        passwordField.placeholder = .password
        
        loginButton.setTitle(.alreadyMember, for: [])
        loginButton.setFont(Text.style5.font)
        loginButton.setTitleColor(.white, for: [])
        
        copyrightLabel.text = .copyrightText
        copyrightLabel.textColor = .white
        copyrightLabel.font = Text.style12.font
        
        nameField.delegate = self
        emailField.delegate = self
        passwordField.delegate = self
        
        scrollView.delegate = self
        
        NotificationCenter.default.addObserver(forName: AccountDeleteViewModel.accountDeleteSuccessNotification, object: nil, queue: nil) { [weak self] notif in
            // Height of 80 because this controller doesn't have a navigation bar
            self?.view.showNotificationBanner(height: 80, title: "Your account was successfully deleted".localized())
        }
    }

    @IBAction func signUpAction(_ sender: RoundedButton) {
        guard
            areFieldsValid,
            let termsConditionsVC = UIViewController.create(
                withIdentifier: .termsConditions,
                from: .authentication
            ) as? TermsConditionsPopup
        else {
            showAlert(title: .error, message: .invalidFields)
            return
        }
    
        termsConditionsVC.delegate = self
        navigationController?.present(termsConditionsVC, animated: true)
    }
    
    @IBAction
    func alreadyMemberAction(_ sender: UIButton) {
        let vc = UIViewController.create(withIdentifier: .login, from: .authentication)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func signUp() {
        // TODO: Modify SignUpCredentials to use codable protocol
        let loginCredentials = LoginCredentials(emailField.text!, passwordField.text!)
        
        let signUpCredentials = SignUpCredentials(
            nameField.text!,
            loginCredentials
        )
        
        showSpinner(colored: .white)
        closeKeyboard()
        
        viewModel?.signUp(with: signUpCredentials, then: { status in
            DispatchQueue.main.async {
                self.handleSignUpStatus(status)
            }
        })
    }
    
    func performBackgroundLogin() {
        guard
            let email = emailField.text,
            let password = passwordField.text else { return }
        
        let credentials = LoginCredentials(email, password)
        
        viewModel?.login(with: credentials, then: { status in
            DispatchQueue.main.async {
                self.handleLoginStatus(status, credentials: credentials)
            }
        })
    }
    
    private func handleSignUpStatus(_ status: RequestStatus) {
        switch status {
        case .success:
            performBackgroundLogin()
        case .error(let message):
            hideSpinner()
            showAlert(title: .error, message: message)
        }
    }
    
    private func handleLoginStatus(_ status: LoginStatus, credentials: LoginCredentials) {
        hideSpinner()
        
        switch status {
        case .success:
            navigationController?.display(.twoStepVerification, from: .authentication)
        case .mfaToken:
            PreferencesManager.shared.set(credentials.email, forKey: Constants.Keys.StorageKeys.emailStorageKey)
            navigationController?.display(.verificationCode, from: .authentication)
        case .error(let message):
            showAlert(title: .error, message: message)
        }
    }
}

extension SignUpViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        print(scrollView.contentOffset)
    }
}

extension SignUpViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        (textField as? TextField)?.toggleBorder(active: true)
        
        let point = CGPoint(x: 0, y: textField.frame.origin.y - 10)
        scrollView.setContentOffset(point, animated: true)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        (textField as? TextField)?.toggleBorder(active: false)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nameField {
            emailField.becomeFirstResponder()
            return true
        } else if textField == emailField {
            passwordField.becomeFirstResponder()
            return true
        } else {
            view.endEditing(true)
            scrollView.setContentOffset(.zero, animated: true)
            return false
        }
    }
}

extension SignUpViewController: TermsConditionsPopupDelegate {
    func didAccept() {
        signUp()
    }
}
