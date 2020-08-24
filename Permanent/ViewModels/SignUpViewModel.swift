//
//  LoginViewModel.swift
//  Permanent
//
//  Created by Gabi Tiplea on 14/08/2020.
//  Copyright © 2020 Lucian Cerbu. All rights reserved.
//

import UIKit

class SignUpViewModel: ViewModelInterface {
  weak var delegate: SignUpViewModelDelegate?
}

protocol SignUpViewModelDelegate: ViewModelDelegateInterface {
  func updateTitle(with text: String?)
}
