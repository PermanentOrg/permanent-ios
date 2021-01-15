//  
//  ShareDetails.swift
//  Permanent
//
//  Created by Adrian Creteanu on 12.01.2021.
//

import Foundation

protocol ShareDetails {
    
    var archiveName: String { get }
    
    var accountName: String { get }
    
    var sharedFileName: String { get }
    
    var hasAccess: Bool { get }
    
    var showPreview: Bool { get }
    
    var archiveThumbURL: URL? { get }
    
    var status: ShareStatus { get set }
    
}
