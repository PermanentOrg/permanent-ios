//
//  LoginViewModel.swift
//  Permanent
//
//  Created by Gabi Tiplea on 14/08/2020.
//  Copyright © 2020 Lucian Cerbu. All rights reserved.
//

import Foundation

class LoginViewModel {
  weak var delegate: LoginViewModelDelegate?

  func processText(text: String?) {
    guard let text = text else { return }
    let modifiedText = text + " modified"
    DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: { [weak self] in
      self?.delegate?.updateTitle(with: modifiedText)
    })
  }
}

protocol LoginViewModelDelegate: class {
  func updateTitle(with text: String?)
}
