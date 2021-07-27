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
    
    func itemFor(row: Int) -> NotificationProtocol
    
    // Events
    
    func start()
    
    var isBusy: Bool { get }
    
}

protocol ActivityFeedViewModelViewDelegate: AnyObject {
    
    func updateScreen(status: RequestStatus)
    
    func updateSpinner(isLoading: Bool)
    
}
