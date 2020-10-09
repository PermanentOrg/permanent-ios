//
//  ViewModelInterface.swift
//  Permanent
//
//  Created by Gabi Tiplea on 17/08/2020.
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
