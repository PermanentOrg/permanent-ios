//
//  UIImageExtension.swift
//  Permanent
//
//  Created by Adrian Creteanu on 15/10/2020.
//

import UIKit

extension UIImage {
    var original: UIImage {
        return self.withRenderingMode(.alwaysOriginal)
    }
    
    var templated: UIImage? {
        return self.withRenderingMode(.alwaysTemplate)
    }
}


extension UIImage {
    static let `public` = UIImage(named: "public")!
    
    static let appsNotification = UIImage(named: "appsNotification")!
    static let archiveNotification = UIImage(named: "archiveNotification")!
    static let accountNotification = UIImage(named: "accountNotification")!
    static let relationshipsNotification = UIImage(named: "relationshipsNotification")!
    static let sharesNotification = UIImage(named: "sharesNotification")!
    static let alert = UIImage(named: "alert")!
    static let chicken = UIImage(named: "chicken")!
    static let close = UIImage(named: "close")!
    static let cloud = UIImage(named: "cloud")!
    static let delete = UIImage(named: "delete")!
    static let deleteAction = UIImage(named: "deleteAction")!
    static let download = UIImage(named: "download")!
    static let edit = UIImage(named: "edit")!
    static let editAction = UIImage(named: "editAction")!
    static let emptyFolder = UIImage(named: "emptyFolder")!
    static let emptySearch = UIImage(named: "emptySearch")!
    static let expand = UIImage(named: "expand")!
    static let folder = UIImage(named: "folder")!
    static let group = UIImage(named: "group")!
    static let info = UIImage(named: "info")!
    static let hamburger = UIImage(named: "hamburger")!
    static let mail = UIImage(named: "mail")!
    static let more = UIImage(named: "more")!
    static let moreAction = UIImage(named: "moreAction")!
    static let logOut = UIImage(named: "logOut")!
    static let placeholder = UIImage(named: "placeholder")!
    static let power = UIImage(named: "power")!
    static let profile = UIImage(named: "profile")!
    static let reply = UIImage(named: "reply")!
    static let removeAction = UIImage(named: "removeAction")!
    static let relationships = UIImage(named: "relationships")!
    static let settings = UIImage(named: "settings")!
    static let security = UIImage(named: "security")!
    static let accountInfo = UIImage(named: "accountInfo")!
    static let share = UIImage(named: "share")!
    static let shares = UIImage(named: "shares")!
    static let storage = UIImage(named: "storage")!
    static let help = UIImage(named: "helpCircle")!
}
