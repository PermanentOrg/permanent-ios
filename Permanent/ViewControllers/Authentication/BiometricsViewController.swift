//
//  BiometricsViewController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 07/10/2020.
//  Copyright © 2020 Victory Square Partners. All rights reserved.
//

import UIKit

class BiometricsViewController: BaseViewController<LoginViewModel> {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var biometricsImageView: UIImageView!
    @IBOutlet var biometricsButton: RoundedButton!
    @IBOutlet var copyrightLabel: UILabel!
    @IBOutlet var loginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initUI()
        viewModel = LoginViewModel()
    }
    
    fileprivate func initUI() {
        view.backgroundColor = .primary
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        titleLabel.text = Translations.welcomeMessage
        titleLabel.textColor = .white
        titleLabel.font = Text.style.font
        
        biometricsButton.setTitle(String(format: Translations.unlockWithBiometrics, BiometryUtils.biometryInfo.name), for: [])
        biometricsImageView.image = UIImage(named: BiometryUtils.biometryInfo.iconName)
            
        loginButton.setTitle(Translations.useLoginCredentials, for: [])
        loginButton.setFont(Text.style5.font)
        loginButton.setTitleColor(.white, for: [])
        
        copyrightLabel.text = Translations.copyrightText
        copyrightLabel.textColor = .white
        copyrightLabel.font = Text.style12.font
    }
    
    @IBAction
    func biometricsCheckAction(_ sender: RoundedButton) {
        PermanentLocalAuthentication.instance.authenticate(onSuccess: {
            DispatchQueue.main.async {
                self.navigationController?.display(.main, from: .main)
            }
        }, onFailure: { error in
            DispatchQueue.main.async {
                self.showAlert(title: Translations.error, message: error.errorDescription)
            }
        })
    }
    
    @IBAction
    func loginButtonAction(_ sender: UIButton) {
        showSpinner()
        viewModel?.logout(then: { logoutStatus in
            self.hideSpinner()
            switch logoutStatus {
                case .success:
                    DispatchQueue.main.async {
                        self.navigationController?.display(.login, from: .authentication)
                    }
                    
                case .error(let message):
                    DispatchQueue.main.async {
                        self.showAlert(title: Translations.error, message: message)
                    }
            }
        })
    }
}
