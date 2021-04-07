//
//  NotificationService.swift
//  PushExtension
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
            case "share-notification":
                guard let targetArchiveName = userInfo["targetArchiveName"] as? String,
                      let sourceArchiveName = userInfo["sourceArchiveName"] as? String,
                      let sharedItemName = userInfo["sharedItemName"] as? String else {
                    contentHandler(bestAttemptContent)
                    return
                }
                
                bestAttemptContent.title = sourceArchiveName
                bestAttemptContent.body = "\(sourceArchiveName) has shared \(sharedItemName) with \(targetArchiveName)"
            //                bestAttemptContent.attachments = [UNNotificationAttachment(identifier: sharedItemName, url: <#T##URL#>, options: nil)]
            
            default: break
            }
            
            contentHandler(bestAttemptContent)
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}
