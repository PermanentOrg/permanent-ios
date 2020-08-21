//
//  LoginViewController.swift
//  Permanent
//
//  Created by Gabi Tiplea on 14/08/2020.
//  Copyright © 2020 Lucian Cerbu. All rights reserved.
//

import UIKit

class LoginViewController: BaseViewController<LoginViewModel> {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var fullNameTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // navigationController?.setNavigationBarHidden(true, animated: false)
        viewModel = LoginViewModel()
        viewModel?.delegate = self
    }
    
    @IBAction func onButtonClicked(_ sender: UIButton) {
    }
}

extension LoginViewController: LoginViewModelDelegate {
    func updateTitle(with text: String?) {
        titleLabel.text = text
    }
}
