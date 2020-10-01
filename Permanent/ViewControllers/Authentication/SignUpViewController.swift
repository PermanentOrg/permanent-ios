//
//  SignUpViewController.swift
//  Permanent
//
//  Created by Gabi Tiplea on 14/08/2020.
//  Copyright © 2020 Lucian Cerbu. All rights reserved.
//

import UIKit

class SignUpViewController: BaseViewController<LoginViewModel> {
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var copyrightLabel: UILabel!
    @IBOutlet private var loginButton: UIButton!
    @IBOutlet private var signUpButton: RoundedButton!
    @IBOutlet private var nameField: CustomTextField!
    @IBOutlet private var emailField: CustomTextField!
    @IBOutlet private var passwordField: CustomTextField!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    fileprivate var areFieldsValid: Bool {
        guard
            nameField.text?.isNotEmpty == true,
            let emailAddress = emailField.text, emailAddress.isNotEmpty, emailAddress.isValidEmail,
            let password = passwordField.text, password.count > 8
        else {
            return false
        }
             
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .primary
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        viewModel = LoginViewModel()

        titleLabel.text = Translations.signup
        titleLabel.textColor = .white
        titleLabel.font = Text.style.font
        
        nameField.placeholder = Translations.fullName
        emailField.placeholder = Translations.email
        passwordField.placeholder = Translations.password
        
        loginButton.setTitle(Translations.alreadyMember, for: [])
        loginButton.setFont(Text.style5.font)
        loginButton.setTitleColor(.white, for: [])
        
        copyrightLabel.text = Translations.copyrightText
        copyrightLabel.textColor = .white
        copyrightLabel.font = Text.style12.font
        
        nameField.delegate = self
        emailField.delegate = self
        passwordField.delegate = self
        
        #if DEBUG
        nameField.text = "Adrian Crt"
        emailField.text = "adrian.creteanu+2@vspartners.us"
        passwordField.text = "Test1234"
        #endif
    }

    @IBAction func signUpAction(_ sender: RoundedButton) {
        guard
            // areFieldsValid,
            let termsConditionsVC = navigationController?.create(
                viewController: .termsConditions,
                from: .authentication
            ) as? TermsConditionsPopup
        else {
            showAlert(title: Translations.error, message: "Fields are invalid!")
            return
        }
    
        termsConditionsVC.delegate = self
        navigationController?.present(termsConditionsVC, animated: true)
    }
    
    @IBAction
    func alreadyMemberAction(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: StoryboardName.authentication.name, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: ViewControllerIdentifier.login.identifier)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func signUp() {
        // TODO: Modify SignUpCredentials to use codable protocol
        let loginCredentials = LoginCredentials(emailField.text!, passwordField.text!)
        
        let signUpCredentials = SignUpCredentials(
            nameField.text!,
            loginCredentials
        )
        
        activityIndicator.startAnimating()
        
        viewModel?.signUp(with: signUpCredentials, then: { status in
            DispatchQueue.main.async {
                self.handleSignUpStatus(status)
            }
        })
    }
    
    func performBackgroundLogin() {
        // TODO: Change name
        
        let email = emailField.text!
        let pass = passwordField.text!
        let c = LoginCredentials(email, pass)
        
        viewModel?.login(with: c, then: { status in
            DispatchQueue.main.async {
                self.handleLoginStatus(status, credentials: c)
            }
        })
    }
    
    private func handleSignUpStatus(_ status: RequestStatus) {
        switch status {
        case .success:
            performBackgroundLogin()
        case .error:
            activityIndicator.stopAnimating()
            showAlert(title: Translations.error, message: Translations.errorMessage)
        }
    }
    
    private func handleLoginStatus(_ status: LoginStatus, credentials: LoginCredentials) {
        activityIndicator.stopAnimating()
        
        switch status {
        case .success:
            navigationController?.navigate(to: .twoStepVerification, from: .authentication)
//        case .mfaToken:
//            PreferencesManager.shared.set(credentials.email, forKey: Constants.Keys.StorageKeys.emailStorageKey)
//            navigationController?.navigate(to: .verificationCode, from: .authentication)
        case .error:
            
            showAlert(title: Translations.error, message: Translations.errorMessage)
            
        default:
            break
        }
    }
}

extension SignUpViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        (textField as? TextField)?.toggleBorder(active: true)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        (textField as? TextField)?.toggleBorder(active: false)
    }
}

extension SignUpViewController: TermsConditionsPopupDelegate {
    func didAccept() {
        signUp()
    }
}
