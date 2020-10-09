//
//  MainViewModel.swift
//  Permanent
//
//  Created by Adrian Creteanu on 24/09/2020.
//

import Foundation

class MainViewModel: ViewModelInterface {
    weak var delegate: MainViewModelDelegate?
}

protocol MainViewModelDelegate: ViewModelDelegateInterface {
    
}
