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
    
    public mutating func safeRemoveFirst() {
        guard !isEmpty else { return }
        
        removeFirst()
    }
}

extension Sequence where Element: Hashable {
    func uniqued() -> [Element] {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
    }
}
