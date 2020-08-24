//
//  PageModelDelegateInterface.swift
//  Permanent
//
//  Created by Lucian Cerbu on 24/08/2020.
//  Copyright © 2020 Lucian Cerbu. All rights reserved.
//

import Foundation

protocol PageViewModelDelegateInterface: ViewModelDelegateInterface {
    func createViewControllers()
    func setViewController(of index:Int)
    func numberOfViewControllers() -> Int
}
