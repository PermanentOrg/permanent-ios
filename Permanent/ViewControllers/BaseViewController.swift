//
//  BaseViewController.swift
//  Permanent
//
//  Created by Gabi Tiplea on 17/08/2020.
//  Copyright © 2020 Lucian Cerbu. All rights reserved.
//

import UIKit

class BaseViewController<T: ViewModelInterface>: UIViewController {

  var viewModel: T?

  override func viewDidLoad() {
    super.viewDidLoad()
  }
}
