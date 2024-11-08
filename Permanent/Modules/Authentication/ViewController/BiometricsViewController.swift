//
//  BiometricsViewController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 07/10/2020.
//

import UIKit
import SwiftUI

class BiometricsViewController: BaseViewController<AuthViewModel> {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var loginButton: UIButton!
    @IBOutlet var biometricsButton: UIButton!
    @IBOutlet weak var leadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var trailingConstraint: NSLayoutConstraint!
    var isCheckingBiometrics = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initUI()
        viewModel = AuthViewModel()
        attemptBiometricsAuth()
    }
    
    fileprivate func initUI() {
        view.backgroundColor = .primary
        if !Constants.Design.isPhone {
            leadingConstraint.constant = view.frame.width * 0.36
            trailingConstraint.constant = view.frame.width * 0.36
        }
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [
            UIColor(red: 0.075, green: 0.106, blue: 0.29, alpha: 1).cgColor,
            UIColor(red: 0.213, green: 0.266, blue: 0.575, alpha: 1).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        view.layer.insertSublayer(gradientLayer, at: 0)
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        titleLabel.text = "Welcome back!"
        titleLabel.textColor = .white
        titleLabel.font = TextFontStyle.style46.font
        
        biometricsButton.setTitle(String(format: .unlockWithBiometrics, BiometryUtils.biometryInfo.name), for: [])
        biometricsButton.setFont(TextFontStyle.style50.font)
        biometricsButton.setImage(UIImage(named: "biometricsUnlockIcon")?.withTintColor(UIColor(Color.blue900)), for: .normal)
        biometricsButton.setImage(UIImage(named: "biometricsUnlockIcon")?.withTintColor(UIColor(Color.blue900.opacity(0.6))), for: .highlighted)
        biometricsButton.setTitleColor(UIColor(Color.blue900), for: .normal)
        biometricsButton.setTitleColor(UIColor(Color.blue900).withAlphaComponent(0.6), for: .highlighted)
        biometricsButton.configuration?.imagePadding = 16
        biometricsButton.configuration?.imagePlacement = .trailing
        biometricsButton.layer.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1).cgColor
        biometricsButton.layer.cornerRadius = 12
        biometricsButton.layer.borderWidth = 1
        biometricsButton.layer.borderColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.32).cgColor
            
        loginButton.setTitle(.useLoginCredentials, for: [])
        loginButton.setFont(TextFontStyle.style50.font)
        loginButton.layer.cornerRadius = 12
        loginButton.layer.borderWidth = 1
        loginButton.layer.borderColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.32).cgColor
        loginButton.setTitleColor(.white, for: [.normal])
        loginButton.setTitleColor(.white.withAlphaComponent(0.9), for: [.highlighted])
    }
    
    private func attemptBiometricsAuth() {
        guard !isCheckingBiometrics else { return }
        isCheckingBiometrics = true
        PermanentLocalAuthentication.instance.authenticate(onSuccess: {
            self.isCheckingBiometrics = false
            DispatchQueue.main.async {
                EventsManager.trackEvent(event: .SignIn)
                let defaultArchive: Int? = AuthenticationManager.shared.session?.account.defaultArchiveID
                
                if defaultArchive == nil {
                    let screenView = OnboardingView(viewModel: OnboardingContainerViewModel(username: nil, password: nil))
                    let host = UIHostingController(rootView: screenView)
                    host.modalPresentationStyle = .fullScreen
                    AppDelegate.shared.rootViewController.present(host, animated: true)
                } else {
                    AppDelegate.shared.rootViewController.setDrawerRoot()
                }
            }
        }, onFailure: { error in
            self.isCheckingBiometrics = false
            self.handleBiometricsFailure(error)
        })
    }
    
    //add a action for the biometrics button view pressed
    @IBAction func biometricsCheckAction(_ sender: Any) {
        attemptBiometricsAuth()
    }
    
    @IBAction
    func loginButtonAction(_ sender: UIButton) {
        logout()
    }
    
    private func logout() {
        showSpinner(colored: .white)
        viewModel?.logout(then: { logoutStatus in
            self.hideSpinner()
            switch logoutStatus {
            case .success:
                DispatchQueue.main.async {
                    self.navigationController?.display(.signUp, from: .authentication)
                }
            case .error(let message):
                DispatchQueue.main.async {
                    self.showAlert(title: .error, message: message)
                }
            }
        })
    }
    
    private func handleBiometricsFailure(_ error: PermanentError) {
        switch error.statusCode {
        // Too many attempts, log out the user.
        case LocalAuthErrors.biometryLockoutError.statusCode:
            logout()
            
        // User does not have biometrics & pincode enrolled.
        case LocalAuthErrors.notEnroledError.statusCode:
            DispatchQueue.main.async {
                self.showAlert(title: .error,
                               message: String(format: .biometricsSetup, BiometryUtils.biometryInfo.name))
            }
            
        // Nothing to do here. Case treated by `loggedin` API call.
        case LocalAuthErrors.localHardwareUnavailableError.statusCode:
            break

        default:
            DispatchQueue.main.async {
                self.showAlert(title: .error, message: error.errorDescription)
            }
        }
    }
}
