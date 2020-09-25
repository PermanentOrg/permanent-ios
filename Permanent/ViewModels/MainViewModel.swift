//
//  MainViewModel.swift
//  Permanent
//
//  Created by Adrian Creteanu on 24/09/2020.
//  Copyright © 2020 Victory Square Partners. All rights reserved.
//

import Foundation

class MainViewModel: ViewModelInterface {
    weak var delegate: MainViewModelDelegate?
}

protocol MainViewModelDelegate: ViewModelDelegateInterface {
    
}
