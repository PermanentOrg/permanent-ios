//  
//  SharePreviewViewModelDelegate.swift
//  Permanent
//
//  Created by Adrian Creteanu on 12.01.2021.
//

import Foundation

protocol SharePreviewViewModelDelegate {
    
    var viewDelegate: SharePreviewViewModelViewDelegate? { get set }
    
    // Data Source
    
    var numberOfItems: Int { get }
    
    func itemFor(row: Int) -> File 
    
    // Events
    
    func start()
    
    func performAction()
    
    var isBusy: Bool { get }
        
    var shareDetails: ShareDetails? { get }
    
}

protocol SharePreviewViewModelViewDelegate: AnyObject {
    
    func updateScreen(status: RequestStatus, shareDetails: ShareDetails?)
    
    func updateShareAccess(status: RequestStatus, shareStatus: ShareStatus?)
    
    func viewInArchive()
    
    func updateSpinner(isLoading: Bool)
    
}
