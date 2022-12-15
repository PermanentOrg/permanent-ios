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
    @IBOutlet weak var newToPermanentLabel: UILabel!
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var separatorViewHeight: NSLayoutConstraint!
    
    let fusionAuthRepository = FusionAuthRepository()
    
    private let overlayView = UIView()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initUI()
    }
    
    fileprivate func initUI() {
        view.backgroundColor = .darkBlue
        
        viewModel = AuthViewModel()
        
        loginLabel.text = "Sign in".localized()
        loginLabel.textColor = .tangerine
        loginLabel.font = Text.style.font
        
        emailField.placeholder = .email
        passwordField.placeholder = .password
        
        loginButton.setTitle("Sign in", for: .normal)
        loginButton.setFont(Text.style16.font)
        loginButton.setTitleColor(.primary, for: [])
        loginButton.layer.cornerRadius = 0
        
        signUpButton.setTitle(.signup, for: [])
        signUpButton.setFont(Text.style5.font)
        signUpButton.setTitleColor(.white, for: [])
        
        forgotPasswordButton.setTitle(.forgotPassword, for: [])
        forgotPasswordButton.setFont(Text.style5.font)
        forgotPasswordButton.setTitleColor(.white, for: [])
        
        copyrightLabel.text = .copyrightText
        copyrightLabel.textColor = .white.withAlphaComponent(0.5)
        copyrightLabel.font = Text.style12.font
        
        newToPermanentLabel.textColor = .white.withAlphaComponent(0.5)
        newToPermanentLabel.backgroundColor = .darkBlue
        newToPermanentLabel.font = Text.style30.font
        
        separatorView.backgroundColor = .white.withAlphaComponent(0.5)
        separatorViewHeight.constant = 1.0 / UIScreen.main.scale
        
        emailField.delegate = self
        passwordField.delegate = self
    }
    
    // MARK: - Actions
    private func attemptLogin() {
        closeKeyboard()
        showSpinner()
        
        viewModel?.login(withUsername: emailField.text, password: passwordField.text, then: { loginStatus in
            self.hideSpinner()
            
            switch loginStatus {
            case .success:
                if AuthenticationManager.shared.session?.account.defaultArchiveID != nil {
                    AppDelegate.shared.rootViewController.setDrawerRoot()
                } else {
                    AppDelegate.shared.rootViewController.setRoot(named: .accountOnboarding, from: .accountOnboarding)
                }
                
            case .mfaToken:
                let verificationCodeVC = UIViewController.create(withIdentifier: .verificationCode, from: .authentication) as! CodeVerificationController
                self.present(verificationCodeVC, animated: true)
                
            case .error(message: let message):
                self.showAlert(title: .error, message: message)
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
        let vc = UIViewController.create(withIdentifier: .recoverPassword, from: .authentication)
        navigationController?.pushViewController(vc, animated: true)
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
