//
//  SplashViewController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 25/09/2020.
//

import UIKit

class SplashViewController: BaseViewController<SplashViewModel> {
    private var logoImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initUI()
        
        viewModel = SplashViewModel()
        viewModel?.verifyLoggedIn(then: { status in
            self.handleAuthState(status)
        })
    }
    
    fileprivate func initUI() {
        view.backgroundColor = .primary
        logoImageView = UIImageView()
        logoImageView.image = UIImage(named: "LogoNameLarge")
        logoImageView.contentMode = .scaleAspectFit
        
        view.addSubview(logoImageView)
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -70),
            logoImageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5)
        ])
    }

    fileprivate func handleAuthState(_ status: AuthStatus) {
        switch status {
        case .loggedIn:
            let authStatus = PermanentLocalAuthentication.instance.canAuthenticate()
            
            if authStatus.error?.statusCode == LocalAuthErrors.localHardwareUnavailableError.statusCode {
                AppDelegate.shared.rootViewController.setRoot(named: .main, from: .main)
            } else {
                AppDelegate.shared.rootViewController.setRoot(named: .biometrics, from: .authentication)
            }
            
        default:
            handleLoggedOutState()
        }
    }
    
    private func handleLoggedOutState() {
        let isNewUser: Bool = PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.isNewUserStorageKey) ?? true
        let route: (ViewControllerIdentifier, StoryboardName) = isNewUser ?
            (.onboarding, .onboarding) :
            (.signUp, .authentication)
        
        AppDelegate.shared.rootViewController.setRoot(named: route.0, from: route.1)
    }
}
