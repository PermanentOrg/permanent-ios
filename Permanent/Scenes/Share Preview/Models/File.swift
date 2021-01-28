//  
//  File.swift
//  Permanent
//
//  Created by Adrian Creteanu on 12.01.2021.
//

import Foundation

protocol File {
    
    var name: String { get }
    
    var date: String { get }
    
    var thumbStringURL: String { get } // TODO
    
}
