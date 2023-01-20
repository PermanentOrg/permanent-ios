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
    @IBOutlet private var nameField: AuthTextField!
    @IBOutlet private var emailField: AuthTextField!
    @IBOutlet private var passwordField: AuthTextField!
    
    @IBOutlet weak var loginLabel: UILabel!
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var separatorViewHeight: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .primary
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        viewModel = AuthViewModel()

        initUI()
        
        NotificationCenter.default.addObserver(forName: AccountDeleteViewModel.accountDeleteSuccessNotification, object: nil, queue: nil) { [weak self] notif in
            // Height of 80 because this controller doesn't have a navigation bar
            self?.view.showNotificationBanner(height: 80, title: "Your account was successfully deleted".localized())
        }
    }
    
    func initUI() {
        titleLabel.text = .signup
        titleLabel.textColor = .tangerine
        titleLabel.font = Text.style.font
        
        nameField.placeholder = .fullName.uppercased()
        nameField.accessibilityLabel = "Full Name"
        emailField.placeholder = .email.uppercased()
        emailField.accessibilityLabel = "Email"
        passwordField.placeholder = .password.uppercased()
        passwordField.accessibilityLabel = "Password"
        
        loginButton.setTitle("Sign in".localized(), for: .normal)
        loginButton.setFont(Text.style5.font)
        loginButton.setTitleColor(.white, for: [])
        
        signUpButton.setTitle(.signup, for: [])
        signUpButton.setFont(Text.style16.font)
        signUpButton.setTitleColor(.primary, for: [])
        signUpButton.layer.cornerRadius = 0
        
        copyrightLabel.text = .copyrightText
        copyrightLabel.textColor = .white.withAlphaComponent(0.5)
        copyrightLabel.font = Text.style12.font
        
        loginLabel.text = "ALREADY REGISTERED?".localized()
        loginLabel.textColor = .white.withAlphaComponent(0.5)
        loginLabel.backgroundColor = .darkBlue
        loginLabel.font = Text.style30.font
        loginLabel.setTextSpacingBy(value: 0.8)
        
        separatorView.backgroundColor = .white.withAlphaComponent(0.5)
        separatorViewHeight.constant = 1.0 / UIScreen.main.scale
        
        nameField.delegate = self
        emailField.delegate = self
        passwordField.delegate = self
        scrollView.delegate = self
    }

    @IBAction func signUpAction(_ sender: RoundedButton) {
        closeKeyboard()
        scrollView.setContentOffset(.zero, animated: false)
        
        guard
            viewModel?.areFieldsValid(nameField: nameField.text, emailField: emailField.text, passwordField: passwordField.text) ?? false,
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
//        showSpinner()
//        AuthenticationManager.shared.performLoginFlow(fromPresentingVC: self) { [self] status in
//            hideSpinner()
//
//            if status == .success {
//                if AuthenticationManager.shared.session?.account.defaultArchiveID != nil {
//                    AppDelegate.shared.rootViewController.setDrawerRoot()
//                } else {
//                    AppDelegate.shared.rootViewController.setRoot(named: .accountOnboarding, from: .accountOnboarding)
//                }
//            } else {
//                showErrorAlert(message: .errorMessage)
//            }
//        }
    }
    
    func signUp() {
        let loginCredentials = LoginCredentials(emailField.text!, passwordField.text!)
        
        let signUpCredentials = SignUpCredentials(
            nameField.text!,
            loginCredentials
        )
        
        showSpinner(colored: .white)
        
        viewModel?.signUp(with: signUpCredentials, then: { status in
            self.handleSignUpStatus(status)
        })
    }
    
    private func handleSignUpStatus(_ status: RequestStatus) {
        hideSpinner()
        
        switch status {
        case .success:
            if AuthenticationManager.shared.session?.account.defaultArchiveID != nil {
                AppDelegate.shared.rootViewController.setDrawerRoot()
            } else {
                AppDelegate.shared.rootViewController.setRoot(named: .accountOnboarding, from: .accountOnboarding)
            }
            
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
