//  
//  UITableViewExtension.swift
//  Permanent
//
//  Created by Adrian Creteanu on 15.01.2021.
//

import UIKit

extension UITableView {
    
    public func reloadData(_ completion: (() -> ())? = nil) {
        UIView.animate(withDuration: 0, animations: {
            self.reloadData()
        }, completion:{ _ in
            completion?()
        })
    }
}
