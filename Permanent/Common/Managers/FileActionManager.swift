//  
//  FileActionManager.swift
//  Permanent
//
//  Created by Adrian Creteanu on 18.11.2020.
//

import Foundation

protocol ContextAction {
    func copy()
    func move()
}

class FileActionManager: ContextAction {
    let file: FileViewModel
    let action: FileAction
    
    init(file: FileViewModel, action: FileAction) {
        self.file = file
        self.action = action
    }
    
    func copy() { }
    
    func move() { }
}
