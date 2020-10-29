//
//  ArrayExtension.swift
//  Permanent
//
//  Created by Adrian Creteanu on 28/10/2020.
//

import Foundation

extension Array {
    public mutating func prepend(_ newElement: Element) {
        self.insert(newElement, at: self.startIndex)
    }
}
