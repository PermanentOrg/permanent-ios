//
//  BiometricsViewController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 07/10/2020.
//  Copyright © 2020 Victory Square Partners. All rights reserved.
//

import UIKit

class BiometricsViewController: UIViewController {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var biometricsImageView: UIImageView!
    @IBOutlet var biometricsButton: RoundedButton!
    @IBOutlet var copyrightLabel: UILabel!
    @IBOutlet var loginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initUI()
    }
    
    fileprivate func initUI() {
        view.backgroundColor = .primary
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        titleLabel.text = Translations.welcomeMessage
        titleLabel.textColor = .white
        titleLabel.font = Text.style.font
        
        biometricsButton.setTitle(String(format: Translations.unlockWithBiometrics, BiometryUtils.biometryName), for: [])
            
        loginButton.setTitle(Translations.useLoginCredentials, for: [])
        loginButton.setFont(Text.style5.font)
        loginButton.setTitleColor(.white, for: [])
        
        copyrightLabel.text = Translations.copyrightText
        copyrightLabel.textColor = .white
        copyrightLabel.font = Text.style12.font
    }
    
    @IBAction func biometricsCheckAction(_ sender: RoundedButton) {
        PermanentLocalAuthentication.instance.authenticate {
            print("Succ")
        } onFailure: { error in
            print(error)
        }
    }
    
    @IBAction func loginButtonAction(_ sender: UIButton) {
        navigationController?.display(.login, from: .authentication)
    }
}
