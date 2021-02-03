//
//  Notification.swift
//  Permanent
//
//  Created by Adrian Creteanu on 22.01.2021.
//

import Foundation

protocol Notification {
    var message: String { get }
    
    var date: String { get }
    
    var type: NotificationType { get }
    
}
