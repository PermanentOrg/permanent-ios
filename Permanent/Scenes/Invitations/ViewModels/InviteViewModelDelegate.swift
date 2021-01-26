//  
//  InviteViewModelDelegate.swift
//  Permanent
//
//  Created by Adrian Creteanu on 26.01.2021.
//

import Foundation

protocol InviteViewModelDelegate {
    
    var viewDelegate: InviteViewModelViewDelegate? { get set }
    
    // Data Source
    
    var numberOfItems: Int { get }
    
    func itemFor(row: Int) -> Invite
    
    // Events
    
    func start()
    
    var isBusy: Bool { get }
    
}

protocol InviteViewModelViewDelegate: class {
    
    func updateScreen(status: RequestStatus)
    
    func updateSpinner(isLoading: Bool)
    
}
