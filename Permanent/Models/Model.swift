//  
//  Model.swift
//  Permanent
//
//  Created by Adrian Creteanu on 09/11/2020.
//

import Foundation

public protocol Model: Codable {
    // Models should provide their own decoders & encoders.
    static var decoder: JSONDecoder { get }
    static var encoder: JSONEncoder { get }
}

public extension Model {
    static var decoder: JSONDecoder { JSONDecoder() }
      
    static var encoder: JSONEncoder { JSONEncoder() }
}
