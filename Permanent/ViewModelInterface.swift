//
//  ViewModelInterface.swift
//  Permanent
//
//  Created by Gabi Tiplea on 17/08/2020.
//  Copyright © 2020 Lucian Cerbu. All rights reserved.
//

import Foundation

protocol ViewModelInterface {
    func viewDidLoad()
    func viewWillAppear()
    func viewWillDisappear()
}

extension ViewModelInterface {
    func viewDidLoad() {}
    func viewWillAppear() {}
    func viewWillDisappear() {}
}
