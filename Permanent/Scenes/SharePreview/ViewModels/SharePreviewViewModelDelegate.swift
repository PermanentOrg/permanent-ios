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
    
    var isBusy: Bool { get }
    
}

protocol SharePreviewViewModelViewDelegate: class {
    
    func updateScreen(status: RequestStatus, shareDetails: ShareDetails?)
    
    func updateSpinner(isLoading: Bool)
    
}
