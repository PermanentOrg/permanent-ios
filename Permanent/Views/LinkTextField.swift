//  
//  LinkTextField.swift
//  Permanent
//
//  Created by Adrian Creteanu on 04.12.2020.
//

import UIKit

class LinkTextField: TextField {
    
    override func setup() {
        
        // TD: create extension  for this
        contentEdgeInsets = UIEdgeInsets(top: 8,
                                         left: 10,
                                         bottom: 8,
                                         right: 10)
        
        isEnabled = false
        backgroundColor = .galleryGray
        layer.borderColor = UIColor.doveGray.cgColor
        tintColor = .dustyGray
        textColor = .dustyGray
        placeholderColor = .dustyGray
    }
}
