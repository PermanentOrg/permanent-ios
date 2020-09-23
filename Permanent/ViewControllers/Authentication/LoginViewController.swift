//
//  LoginViewController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 17/09/2020.
//  Copyright © 2020 Lucian Cerbu. All rights reserved.
//

import UIKit

class LoginViewController: BaseViewController<LoginViewModel> {
    @IBOutlet private var loginLabel: UILabel!
    @IBOutlet private var copyrightLabel: UILabel!
    @IBOutlet private var loginButton: RoundedButton!
    @IBOutlet private var forgotPasswordButton: UIButton!
    @IBOutlet private var signUpButton: UIButton!
    @IBOutlet private var emailField: CustomTextField!
    @IBOutlet private var passwordField: CustomTextField!
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initUI()
    }
    
    fileprivate func initUI() {
        view.backgroundColor = .darkBlue
        
        viewModel = LoginViewModel()
        
        loginLabel.text = "Log In"
        loginLabel.textColor = .white
        loginLabel.font = Text.style.font
        
        emailField.placeholder = "Email"
        passwordField.placeholder = "Password"
        
        signUpButton.setFont(Text.style5.font)
        signUpButton.setTitleColor(.white, for: [])
        
        forgotPasswordButton.setFont(Text.style5.font)
        forgotPasswordButton.setTitleColor(.white, for: [])
        
        copyrightLabel.text = "© The Permanent Legacy Foundation 2020"
        copyrightLabel.textColor = .white
        copyrightLabel.font = Text.style12.font
        
        emailField.delegate = self
        passwordField.delegate = self
    }
    
    // MARK: - Actions
    
    @IBAction
    func loginAction(_ sender: RoundedButton) {
        guard
            let email = emailField.text,
            let password = passwordField.text,
            email.isNotEmpty, password.isNotEmpty else { return }
        
        let credentials = LoginCredentials(email, password)
        
        viewModel?.login(with: credentials, then: { status in
            self.handleLoginStatus(status)
        })
    }
    
    @IBAction
    func signUpAction(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction
    func forgotPasswordAction(_ sender: UIButton) {}
    
    fileprivate func handleLoginStatus(_ status: LoginStatus) {
        switch status {
        case .success:
            // TODO: Nav to main page
            break
            
        case .mfaToken:
            DispatchQueue.main.async {
                self.openVerificationPage()
            }
            
        case .error:
            // TODO: Display error alert
            break
        }
    }
    
    fileprivate func openVerificationPage() {
        let storyboard = UIStoryboard(name: StoryboardNames.authentication.name, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: ViewControllerIdentifiers.verificationCode.identifier)
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension LoginViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        (textField as? TextField)?.toggleBorder(active: true)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        (textField as? TextField)?.toggleBorder(active: false)
    }
}
