//
//  SignUpViewController.swift
//  Permanent
//
//  Created by Gabi Tiplea on 14/08/2020.
//

import UIKit
import SwiftUI

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
    @IBOutlet weak var theContainer: UIView!
    var showRegisterView: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .primary
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        viewModel = AuthViewModel()

        //initUI()
        
        let childView = UIHostingController(rootView: AuthenticatorContainerView(viewModel: AuthenticatorContainerViewModel(contentType: showRegisterView ? .register : .login)))
        addChild(childView)
        childView.view.frame = theContainer.bounds
        theContainer.addSubview(childView.view)
        childView.didMove(toParent: self)
        
        
        setupNotifications()
        
        NotificationCenter.default.addObserver(forName: AccountDeleteViewModel.accountDeleteSuccessNotification, object: nil, queue: nil) { [weak self] notif in
            // Height of 80 because this controller doesn't have a navigation bar
        }
    }
    
    func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func initUI() {
        titleLabel.text = .signup
        titleLabel.textColor = .tangerine
        titleLabel.font = TextFontStyle.style.font
        
        nameField.placeholder = .fullName.uppercased()
        nameField.accessibilityLabel = "Full Name"
        emailField.placeholder = .email.uppercased()
        emailField.accessibilityLabel = "Email"
        passwordField.placeholder = .password.uppercased()
        passwordField.accessibilityLabel = "Password"
        
        loginButton.setTitle("Sign in".localized(), for: .normal)
        loginButton.setFont(TextFontStyle.style5.font)
        loginButton.setTitleColor(.white, for: [])
        
        signUpButton.setTitle(.signup, for: [])
        signUpButton.setFont(TextFontStyle.style16.font)
        signUpButton.setTitleColor(.primary, for: [])
        signUpButton.layer.cornerRadius = 0
        
        copyrightLabel.text = .copyrightText
        copyrightLabel.textColor = .white.withAlphaComponent(0.5)
        copyrightLabel.font = TextFontStyle.style12.font
        
        loginLabel.text = "ALREADY REGISTERED?".localized()
        loginLabel.textColor = .white.withAlphaComponent(0.5)
        loginLabel.backgroundColor = .darkBlue
        loginLabel.font = TextFontStyle.style30.font
        loginLabel.setTextSpacingBy(value: 0.8)
        
        separatorView.backgroundColor = .white.withAlphaComponent(0.5)
        separatorViewHeight.constant = 1.0 / UIScreen.main.scale
        
        nameField.delegate = self
        emailField.delegate = self
        passwordField.delegate = self
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
                let screenView = OnboardingView(viewModel: OnboardingContainerViewModel(username: self.emailField.text, password: self.passwordField.text))
                let host = UIHostingController(rootView: screenView)
                host.modalPresentationStyle = .fullScreen
                AppDelegate.shared.rootViewController.present(host, animated: true)
            }
            
            EventsManager.setUserProfile(id: AuthenticationManager.shared.session?.account.accountID,
                                         email: AuthenticationManager.shared.session?.account.primaryEmail)
            EventsManager.trackEvent(event: .SignUp)
        case .error(let message):
            showAlert(title: .error, message: message)
        }
    }
    
    // MARK: - Keyboard
    @objc func keyboardWillShow(_ notification: Notification) {
        guard let scrollView = scrollView,
            let keyBoardInfo = notification.userInfo,
            let endFrame = keyBoardInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
            let window = scrollView.window
        else { return }
        
        let keyBoardFrame = window.convert(endFrame.cgRectValue, to: scrollView.superview)
        
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration((keyBoardInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double))
        UIView.setAnimationCurve(UIView.AnimationCurve(rawValue: (keyBoardInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as! Int))!)
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyBoardFrame.height, right: 0)
        UIView.commitAnimations()
        
        guard let firstResponder: UIView = view.subviews.first(where: { $0.isFirstResponder }) else { return }
        
        scrollView.scrollRectToVisible(firstResponder.frame, animated: true)
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        let keyBoardInfo = notification.userInfo!
        var tableInsets = scrollView.contentInset
        tableInsets.bottom = 0
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration((keyBoardInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double))
        UIView.setAnimationCurve(UIView.AnimationCurve(rawValue: (keyBoardInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as! Int))!)
        scrollView.contentInset = tableInsets
        UIView.commitAnimations()
    }
}

extension SignUpViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nameField {
            _ = emailField.becomeFirstResponder()
            return true
        } else if textField == emailField {
            _ = passwordField.becomeFirstResponder()
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
