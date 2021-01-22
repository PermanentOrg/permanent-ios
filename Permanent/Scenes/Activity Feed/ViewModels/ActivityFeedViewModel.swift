//  
//  ActivityFeedViewModel.swift
//  Permanent
//
//  Created by Adrian Creteanu on 21.01.2021.
//

import Foundation

class ActivityFeedViewModel: ActivityFeedViewModelDelegate {
    
    // MARK: - Delegates
    
    weak var viewDelegate: ActivityFeedViewModelViewDelegate?
    
    // MARK: - Properties
    
    var isBusy: Bool = false {
        didSet {
            
        }
    }
    
    var numberOfItems: Int {
        return 5
    }
    
    func start() {
        fetchNotifications()
    }
    
    // MARK: - Network
    
    func fetchNotifications()  {
        
    }
    
}
