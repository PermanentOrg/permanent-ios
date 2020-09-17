//
//  LoginViewModel.swift
//  Permanent
//
//  Created by Adrian Creteanu on 17/09/2020.
//  Copyright © 2020 Lucian Cerbu. All rights reserved.
//

import Foundation

class LoginViewModel: ViewModelInterface {
    weak var delegate: LoginViewModelDelegate?
}

protocol LoginViewModelDelegate: ViewModelDelegateInterface {}
