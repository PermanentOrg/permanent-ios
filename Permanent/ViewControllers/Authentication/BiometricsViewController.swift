//
//  BiometricsViewController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 07/10/2020.
//

import UIKit

class BiometricsViewController: BaseViewController<AuthViewModel> {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var biometricsImageView: UIImageView!
    @IBOutlet var biometricsButton: RoundedButton!
    @IBOutlet var copyrightLabel: UILabel!
    @IBOutlet var loginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initUI()
        viewModel = AuthViewModel()
        attemptBiometricsAuth()
    }
    
    fileprivate func initUI() {
        view.backgroundColor = .primary
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        titleLabel.text = .welcomeMessage
        titleLabel.textColor = .white
        titleLabel.font = Text.style.font
        
        biometricsButton.setTitle(String(format: .unlockWithBiometrics, BiometryUtils.biometryInfo.name), for: [])
        biometricsImageView.image = UIImage(named: BiometryUtils.biometryInfo.iconName)
            
        loginButton.setTitle(.useLoginCredentials, for: [])
        loginButton.setFont(Text.style5.font)
        loginButton.setTitleColor(.white, for: [])
        
        copyrightLabel.text = .copyrightText
        copyrightLabel.textColor = .white
        copyrightLabel.font = Text.style12.font
    }
    
    private func attemptBiometricsAuth() {
        PermanentLocalAuthentication.instance.authenticate(onSuccess: {
            DispatchQueue.main.async {
                self.viewModel?.getAccountArchives({ result, error in
                    if let result = result,
                       result.allSatisfy({ archive in
                           archive.archiveVO?.status == ArchiveVOData.Status.pending
                       }) {
                        AppDelegate.shared.rootViewController.setRoot(named: .accountOnboarding, from: .accountOnboarding)
                    } else {
                        AppDelegate.shared.rootViewController.setDrawerRoot()
                    }
                })
            }
        }, onFailure: { error in
            self.handleBiometricsFailure(error)
        })
    }
    
    @IBAction
    func biometricsCheckAction(_ sender: RoundedButton) {
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
