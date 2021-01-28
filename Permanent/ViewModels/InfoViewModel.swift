//
//  InfoViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 27.01.2021.
//

import Foundation
import UIKit

class InfoViewModel: ViewModelInterface {
    weak var delegate: InfoViewModelDelegate?
}

protocol InfoViewModelDelegate: ViewModelDelegateInterface {
    
}
