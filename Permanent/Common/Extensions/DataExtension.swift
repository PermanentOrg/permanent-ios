//
//  DataExtension.swift
//  Permanent
//
//  Created by Adrian Creteanu on 22/10/2020.
//

import Foundation

extension Data {
    
    mutating func append<T>(values: [T]) -> Bool {
        var newData = Data()
        var status = true
     
        if T.self == String.self {
            for value in values {
                guard let convertedString = (value as! String).data(using: .utf8) else { status = false; break }
                newData.append(convertedString)
            }
        } else if T.self == Data.self {
            for value in values {
                newData.append(value as! Data)
            }
        } else {
            status = false
        }
     
        if status {
            self.append(newData)
        }
     
        return status
    }
}
