//
//  NavigationStateManager.swift
//  Permanent
//
//  Created by Lucian Cerbu on 12.03.2025.
//
//

import Foundation
import Combine

enum SelectionState: Hashable, Codable {
    case changePassword
    case twoStepVerification
    case none
}

class NavigationStateManager: ObservableObject {
    @Published var selectionState: SelectionState = .none
    @Published var refreshTwoStepData: Bool = false
    
    
    var data: Data? {
        get {
           try? JSONEncoder().encode(selectionState)
        }
        set {
            
            guard let data = newValue,
                  let selectionState = try? JSONDecoder().decode(SelectionState.self, from: data) else {
                return
            }
            
            self.selectionState = selectionState
        }
    }
    
    
    func popToRoot() {
        selectionState = .none
    }
    
    func goToChangePassword() {
        selectionState = .changePassword
    }
    
    func goToTwoStepVerification() {
        selectionState = .twoStepVerification
    }
    
    func updateTwoStepData() {
        refreshTwoStepData = true
    }
    
    var objectWillChangeSequence: AsyncPublisher<Publishers.Buffer<ObservableObjectPublisher>> {
        objectWillChange
            .buffer(size: 1, prefetch: .byRequest, whenFull: .dropOldest)
            .values
    }
}
