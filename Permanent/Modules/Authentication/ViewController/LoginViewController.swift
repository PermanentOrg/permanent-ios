//
//  LoginViewController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 17/09/2020.
//

import UIKit
import SwiftUI

class LoginViewController: BaseViewController<AuthViewModel> {
    @IBOutlet private var scrollView: UIScrollView!
    @IBOutlet private var loginLabel: UILabel!
    @IBOutlet private var copyrightLabel: UILabel!
    @IBOutlet private var loginButton: RoundedButton!
    @IBOutlet private var forgotPasswordButton: UIButton!
    @IBOutlet private var signUpButton: UIButton!
    @IBOutlet private var emailField: AuthTextField!
    @IBOutlet private var passwordField: AuthTextField!
    @IBOutlet weak var newToPermanentLabel: UILabel!
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var separatorViewHeight: NSLayoutConstraint!
    
    private let overlayView = UIView()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNotifications()
        initUI()
    }
    
    func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    fileprivate func initUI() {
        view.backgroundColor = .darkBlue
        
        viewModel = AuthViewModel()
        
        loginLabel.text = "Sign in".localized()
        loginLabel.textColor = .tangerine
        loginLabel.font = TextFontStyle.style.font
        
        emailField.placeholder = .email.uppercased()
        emailField.accessibilityLabel = "Email"
        passwordField.placeholder = .password.uppercased()
        passwordField.accessibilityLabel = "Password"
        
        loginButton.setTitle("Sign in".localized(), for: .normal)
        loginButton.setFont(TextFontStyle.style16.font)
        loginButton.setTitleColor(.primary, for: [])
        loginButton.layer.cornerRadius = 0
        
        signUpButton.setTitle(.signup, for: [])
        signUpButton.setFont(TextFontStyle.style20.font)
        signUpButton.setTitleColor(.white, for: [])
        
        forgotPasswordButton.setTitle(.forgotPassword, for: [])
        forgotPasswordButton.setFont(TextFontStyle.style12.font)
        forgotPasswordButton.setTitleColor(.white, for: [])
        
        copyrightLabel.text = .copyrightText
        copyrightLabel.textColor = .white.withAlphaComponent(0.5)
        copyrightLabel.font = TextFontStyle.style12.font
        
        newToPermanentLabel.textColor = .white.withAlphaComponent(0.5)
        newToPermanentLabel.backgroundColor = .darkBlue
        newToPermanentLabel.font = TextFontStyle.style30.font
        newToPermanentLabel.setTextSpacingBy(value: 0.8)
        
        separatorView.backgroundColor = .white.withAlphaComponent(0.5)
        separatorViewHeight.constant = 1.0 / UIScreen.main.scale
        
        emailField.delegate = self
        passwordField.delegate = self
    }
    
    // MARK: - Actions
    private func attemptLogin() {
        closeKeyboard()
        showSpinner()
        
        viewModel?.login(withUsername: emailField.text, password: passwordField.text, then: {[weak self] loginStatus in
            self?.hideSpinner()
            
            switch loginStatus {
            case .success:
                if AuthenticationManager.shared.session?.account.defaultArchiveID != nil {
                    AppDelegate.shared.rootViewController.setDrawerRoot()
                } else {
                    let screenView = OnboardingView()
                    let host = UIHostingController(rootView: screenView)
                    host.modalPresentationStyle = .fullScreen
                    AppDelegate.shared.rootViewController.present(host, animated: true)
                    //AppDelegate.shared.rootViewController.setRoot(named: .accountOnboarding, from: .accountOnboarding)
                }
                self?.trackEvents()
            case .mfaToken:
                let verificationCodeVC = UIViewController.create(withIdentifier: .verificationCode, from: .authentication) as! CodeVerificationController
                self?.present(verificationCodeVC, animated: true)
                self?.trackEvents()
            case .error(message: let message):
                self?.showAlert(title: .error, message: message)
            }
        })
    }
    
    func trackEvents() {
        EventsManager.setUserProfile(id: AuthenticationManager.shared.session?.account.accountID,
                                     email: AuthenticationManager.shared.session?.account.primaryEmail)
        EventsManager.trackEvent(event: .SignIn)
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

extension LoginViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            _ = passwordField.becomeFirstResponder()
            return true
        } else {
            view.endEditing(true)
            attemptLogin()
            return true
        }
    }
}
