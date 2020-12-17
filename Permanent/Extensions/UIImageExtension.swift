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
    static let close = UIImage(named: "close")!
    static let cloud = UIImage(named: "cloud")!
    static let delete = UIImage(named: "delete")!
    static let deleteAction = UIImage(named: "deleteAction")!
    static let download = UIImage(named: "download")!
    static let emptyFolder = UIImage(named: "emptyFolder")!
    static let folder = UIImage(named: "folder")!
    static let group = UIImage(named: "group")!
    static let info = UIImage(named: "info")!
    static let more = UIImage(named: "more")!
    static let moreAction = UIImage(named: "moreAction")!
    static let placeholder = UIImage(named: "placeholder")!
    static let power = UIImage(named: "power")!
    static let profile = UIImage(named: "profile")!
    static let relationships = UIImage(named: "relationships")!
    static let settings = UIImage(named: "settings")!
    static let share = UIImage(named: "share")!
    static let shares = UIImage(named: "shares")!
}
