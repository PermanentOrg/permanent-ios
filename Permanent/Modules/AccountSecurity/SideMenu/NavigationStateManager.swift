//
//  NavigationStateManager.swift
//  NavigationStackProject
//
//  Created by Karin Prater on 12.11.22.
//

import Foundation
import Combine

enum SelectionState: Hashable, Codable {
    case changePassword
    case twoStepVerification
    case biometricAuth
}

class NavigationStateManager: ObservableObject {
    
    @Published var selectionState: SelectionState? = nil
    
    
    var data: Data? {
        get {
           try? JSONEncoder().encode(selectionState)
        }
        set {
            
            guard let data = newValue,
                  let selectionState = try? JSONDecoder().decode(SelectionState.self, from: data) else {
                return
            }
            
            // fetch updated new model data for each id
            self.selectionState = selectionState
        }
    }
    
    
    func popToRoot() {
       selectionState = nil
    }
    
    func goToChangePassword() {
        selectionState = .changePassword
    }
    
    func goToTwoStepVerification() {
        selectionState = .twoStepVerification
    }
    
    func goToBiometricAuth() {
        selectionState = .biometricAuth
    }
    
    var objectWillChangeSequence: AsyncPublisher<Publishers.Buffer<ObservableObjectPublisher>> {
        objectWillChange
            .buffer(size: 1, prefetch: .byRequest, whenFull: .dropOldest)
            .values
    }
}
