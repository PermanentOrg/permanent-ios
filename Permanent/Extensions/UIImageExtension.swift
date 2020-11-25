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
    static let delete = UIImage(named: "delete")!
    static let deleteAction = UIImage(named: "deleteAction")!
    static let moreAction = UIImage(named: "moreAction")!
    static let more = UIImage(named: "more")!
    static let close = UIImage(named: "close")!
    static let cloud = UIImage(named: "cloud")!
    static let folder = UIImage(named: "folder")!
    static let download = UIImage(named: "download")!
    static let placeholder = UIImage(named: "placeholder")!
    static let profile = UIImage(named: "profile")!
    static let settings = UIImage(named: "settings")!
    static let group = UIImage(named: "group")!
    static let `public` = UIImage(named: "public")!
    static let share = UIImage(named: "share")!
    static let relationships = UIImage(named: "relationships")!
    static let power = UIImage(named: "power")!
    
    
    
    
    
}
