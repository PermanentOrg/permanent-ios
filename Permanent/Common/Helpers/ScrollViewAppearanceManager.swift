//
//  ProfilePageData.swift
//  Permanent
//
//  Created by Lucian Cerbu on 05.06.2025.

import UIKit

class ScrollViewAppearanceManager {
    static let shared = ScrollViewAppearanceManager()
    private var appearanceStack: [(Bool, String)] = []
    
    private init() {}
    
    func pushScrollViewBounce(enabled: Bool, identifier: String) {
        appearanceStack.append((enabled, identifier))
        updateScrollViewBounce()
    }
    
    func popScrollViewBounce(identifier: String) {
        if let index = appearanceStack.lastIndex(where: { $0.1 == identifier }) {
            appearanceStack.remove(at: index)
            updateScrollViewBounce()
        }
    }
    
    private func updateScrollViewBounce() {
        // If no settings are pushed, default to true (bouncing enabled)
        let bounceEnabled = appearanceStack.last?.0 ?? true
        UIScrollView.appearance().bounces = bounceEnabled
    }
    
    func reset() {
        appearanceStack.removeAll()
        updateScrollViewBounce()
    }
} 
