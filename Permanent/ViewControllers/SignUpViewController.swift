//
//  SignUpViewController.swift
//  Permanent
//
//  Created by Gabi Tiplea on 14/08/2020.
//  Copyright © 2020 Lucian Cerbu. All rights reserved.
//

import UIKit

class SignUpViewController: BaseViewController<SignUpViewModel> {
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var existingAccountLabel: UILabel!
  @IBOutlet weak var footerLabel: UILabel!

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
    existingAccountLabel.font = Text.style7.font
    footerLabel.text = "© The Permanent Legacy Foundation 2020"
    footerLabel.textColor = .white
    footerLabel.font = Text.style12.font
  }

  @IBAction func onButtonClicked(_ sender: UIButton) {
  }
}

extension SignUpViewController: SignUpViewModelDelegate {
  func updateTitle(with text: String?) {
    titleLabel.text = text
  }
}
