//  
//  NotificationVM.swift
//  Permanent
//
//  Created by Adrian Creteanu on 22.01.2021.
//

import Foundation

struct NotificationVM: Notification {
    var message: String
    var date: String

    init(notification: NotificationVO) {

        let data = notification.notificationVO
        
        self.message = data?.message ?? ""
        self.date = data?.lastSentDT?.dateOnly ?? ""
    }
}