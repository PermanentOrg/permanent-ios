//
//  NotificationService.swift
//  PermanentPushExtension
//
//  Created by Vlad Alexandru Rusu on 01.04.2021.
//

import UserNotifications

class NotificationService: UNNotificationServiceExtension {
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
            let userInfo = bestAttemptContent.userInfo
            guard let notificationType = userInfo["notificationType"] as? String else {
                contentHandler(bestAttemptContent)
                return
            }
            
            switch notificationType {
            case "type.notification.pa_response_non_transfer":
                guard let accountName = userInfo["fromAccountName"] as? String,
                      let archiveName = userInfo["fromArchiveName"] as? String,
                      let accessRole = userInfo["accessRole"] as? String else {
                          contentHandler(bestAttemptContent)
                          return
                      }
                
                let accessRoleComps = accessRole.components(separatedBy: ".")
                let stylizedAccessRole = accessRoleComps.last?.capitalized ?? accessRole
                
                bestAttemptContent.title = accountName
                bestAttemptContent.body = "\(accountName) accepted your invitation to join the \(archiveName) as a \(stylizedAccessRole)"
                
            case "type.notification.share":
                guard let sourceArchiveName = userInfo["fromAccountName"] as? String else {
                    contentHandler(bestAttemptContent)
                    return
                }
                
                if let sharedItemName = userInfo["recordName"] as? String {
                    bestAttemptContent.title = sourceArchiveName
                    bestAttemptContent.body = "\(sourceArchiveName) has shared \(sharedItemName) with you."
                } else if let sharedFolderName = userInfo["folderName"] as? String {
                    bestAttemptContent.title = sourceArchiveName
                    bestAttemptContent.body = "\(sourceArchiveName) has shared \(sharedFolderName) folder with you."
                } else {
                    contentHandler(bestAttemptContent)
                    return
                }
                
            case "type.notification.sharelink.request":
                guard let sourceAccountName = userInfo["fromAccountName"] as? String,
                      let sharedItemName = userInfo["shareName"] as? String else {
                          contentHandler(bestAttemptContent)
                          return
                      }
                
                bestAttemptContent.title = sourceAccountName
                bestAttemptContent.body = "\(sourceAccountName) has requested access to \(sharedItemName)."
                
            case "type.notification.share.invitation.acceptance":
                let sharedItemName: String
                guard let sourceAccountName = userInfo["invitedEmail"] as? String else {
                    contentHandler(bestAttemptContent)
                    return
                }
                
                if let sharedFileName = userInfo["recordName"] as? String {
                    sharedItemName = sharedFileName
                } else if let sharedFolderName = userInfo["folderName"] as? String {
                    sharedItemName = sharedFolderName
                } else {
                    contentHandler(bestAttemptContent)
                    return
                }
                
                bestAttemptContent.title = sourceAccountName
                bestAttemptContent.body = "\(sourceAccountName) has joined Permanent to access \(sharedItemName)."
                
            case "upload-reminder":
                bestAttemptContent.title = ""
                bestAttemptContent.body = "Preserve your most important documents with peace of mind. We will never mine your data, claim your copyright or invade your privacy."
                
            default: break
            }
            
            contentHandler(bestAttemptContent)
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
}
