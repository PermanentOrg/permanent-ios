//  
//  NotificationVO.swift
//  Permanent
//
//  Created by Adrian Creteanu on 22.01.2021.
//

import Foundation

struct NotificationVO: Model {
    let notificationVO: NotificationVOData?
    
    enum CodingKeys: String, CodingKey {
        case notificationVO = "NotificationVO"
    }
}

struct NotificationVOData: Model {
    let notificationID, fromAccountID, fromArchiveID, toAccountID: Int?
    let toArchiveID: Int?
    let folderLinkID: Int?
    let message: String?
    let redirectURL: String?
    let thumbArchiveNbr: JSONAny?
    let timesSent: Int?
    let lastSentDT, emailKVP: String?
    let status: String?
    let type: String?
    let createdDT, updatedDT: String?

    enum CodingKeys: String, CodingKey {
        case notificationID = "notificationId"
        case fromAccountID = "fromAccountId"
        case fromArchiveID = "fromArchiveId"
        case toAccountID = "toAccountId"
        case toArchiveID = "toArchiveId"
        case folderLinkID = "folder_linkId"
        case message
        case redirectURL = "redirectUrl"
        case thumbArchiveNbr, timesSent, lastSentDT, emailKVP, status, type, createdDT, updatedDT
    }
}


enum NotificationType: String {
    case typeNotificationPaShare = "type.notification.pa_share"
    case typeNotificationPaTransfer = "type.notification.pa_transfer"
}
