//
//  SignUpViewController.swift
//  Permanent
//
//  Created by Gabi Tiplea on 14/08/2020.
//  Copyright © 2020 Lucian Cerbu. All rights reserved.
//

import UIKit

class SignUpViewController: BaseViewController<SignUpViewModel> {
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
        
        viewModel = SignUpViewModel()

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
        let loginCredentials = LoginCredentials(emailField.text!, passwordField.text!)
        
        let signUpCredentials = SignUpCredentials(
            nameField.text!,
            loginCredentials
        )
        
        viewModel?.signUp(with: signUpCredentials, then: { (status) in
            if status == .success {
                DispatchQueue.main.async {
                    self.navigationController?.display(.twoStepVerification, from: .authentication)
                }
            } else {
                // TODO: Pass also the error message along
                DispatchQueue.main.async {
                    self.showAlert(title: Translations.error, message: Translations.errorMessage)
                }
            }
        })
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
