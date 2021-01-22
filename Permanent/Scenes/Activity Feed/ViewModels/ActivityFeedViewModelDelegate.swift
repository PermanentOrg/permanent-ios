//  
//  ActivityFeedViewModelDelegate.swift
//  Permanent
//
//  Created by Adrian Creteanu on 21.01.2021.
//

import Foundation

protocol ActivityFeedViewModelDelegate {
    
    var viewDelegate: ActivityFeedViewModelViewDelegate? { get set }
    
    // Data Source
    
    var numberOfItems: Int { get }
    
    // Events
    
    func start()
    
    var isBusy: Bool { get }
    
}

protocol ActivityFeedViewModelViewDelegate: class {
    
    
    
}
