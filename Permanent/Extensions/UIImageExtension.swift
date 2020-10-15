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
