//
//  SignUpViewController.swift
//  Permanent
//
//  Created by Gabi Tiplea on 14/08/2020.
//  Copyright © 2020 Lucian Cerbu. All rights reserved.
//

import UIKit

class SignUpViewController: BaseViewController<SignUpViewModel> {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var existingAccountLabel: UILabel!
    @IBOutlet var footerLabel: UILabel!
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .darkBlue
        navigationController?.setNavigationBarHidden(true, animated: false)
        viewModel = SignUpViewModel()
        viewModel?.delegate = self

        titleLabel.text = "Sign Up"
        titleLabel.textColor = .white
        titleLabel.font = Text.style.font
        existingAccountLabel.text = "Already have an account?"
        existingAccountLabel.textColor = .white
        existingAccountLabel.font = Text.style5.font
        existingAccountLabel.isUserInteractionEnabled = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(alreadyMemberAction(_:)))
        existingAccountLabel.addGestureRecognizer(tapGesture)
        
        footerLabel.text = "© The Permanent Legacy Foundation 2020"
        footerLabel.textColor = .white
        footerLabel.font = Text.style12.font
    }

    @IBAction func onButtonClicked(_ sender: UIButton) {
        print("Login pressed")
    }
    
    @objc
    func alreadyMemberAction(_ sender: UILabel) {
        print("Loginnnnn")
        
        let storyboard = UIStoryboard(name: "Authentication", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "Login")
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    
}

extension SignUpViewController: SignUpViewModelDelegate {
    func updateTitle(with text: String?) {
        titleLabel.text = text
    }
}
