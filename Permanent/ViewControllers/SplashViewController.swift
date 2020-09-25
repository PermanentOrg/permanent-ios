//
//  SplashViewController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 25/09/2020.
//  Copyright © 2020 Victory Square Partners. All rights reserved.
//

import UIKit

class SplashViewController: BaseViewController<SplashViewModel> {
    private var logoImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initUI()
        
        viewModel = SplashViewModel()
        viewModel?.verifyLoggedIn(then: { status in
            self.handleAuthStatus(status)
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

    fileprivate func handleAuthStatus(_ status: AuthStatus) {
        switch status {
        case .loggedIn:
            AppDelegate.shared.rootViewController.setRoot(named: .main, from: .main)
        default:
            AppDelegate.shared.rootViewController.setRoot(named: .login, from: .authentication)
        }
    }
}
