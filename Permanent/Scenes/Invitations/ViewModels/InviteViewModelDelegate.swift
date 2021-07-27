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
    
    func handleInvite(operation: InviteOperation)
    
    func sendInvite(info: [String]?)
    
    var isBusy: Bool { get }
    
    var hasData: Bool { get }
    
}

protocol InviteViewModelViewDelegate: AnyObject {
    
    func refreshList(afterOperation: InviteOperation, status: RequestStatus)
    
    func updateScreen(status: RequestStatus)
    
    func updateSpinner(isLoading: Bool)
    
    func dismissDialog()
    
}
