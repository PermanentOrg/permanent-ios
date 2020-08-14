//
//  LoginViewController.swift
//  Permanent
//
//  Created by Gabi Tiplea on 14/08/2020.
//  Copyright © 2020 Lucian Cerbu. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var fullNameTextField: UITextField!
  var viewModel: LoginViewModel?

  override func viewDidLoad() {
    super.viewDidLoad()
    viewModel = LoginViewModel()
    viewModel?.delegate = self
  }

  @IBAction func onButtonClicked(_ sender: UIButton) {
    viewModel?.processText(text: fullNameTextField.text)
  }
}

extension LoginViewController: LoginViewModelDelegate {
  func updateTitle(with text: String?) {
    titleLabel.text = text
  }
}
