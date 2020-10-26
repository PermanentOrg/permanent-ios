//
//  UIAlertControllerExtension.swift
//  Permanent
//
//  Created by Adrian Creteanu on 26/10/2020.
//

import UIKit

extension UIAlertController {
    func addActions(_ actions: [UIAlertAction]) {
        actions.forEach { self.addAction($0) }
    }
}
