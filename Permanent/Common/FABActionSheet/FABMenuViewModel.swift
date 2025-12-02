//
//  FABMenuViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 28.11.2025.
//

import SwiftUI

@MainActor
class FABMenuViewModel: ObservableObject {
    @Published var isAnimating: Bool = false
    @Published var backgroundOpacity: Double = 0
    
    private let onDismiss: () -> Void
    
    init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
    }
    
    func startPresentationAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            isAnimating = true
            backgroundOpacity = 1.0
        }
    }
    
    func dismissWithAnimation() {
        withAnimation(.easeIn(duration: 0.25)) {
            isAnimating = false
            backgroundOpacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            self?.onDismiss()
        }
    }
    
    func callOnDismiss() {
        onDismiss()
    }
}
