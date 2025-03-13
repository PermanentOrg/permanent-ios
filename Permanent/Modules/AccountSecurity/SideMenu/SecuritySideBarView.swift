//
//  SecuritySideBarView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 06.03.2025.
import SwiftUI

struct SecuritySideBarView: View {
    @EnvironmentObject var navigationManager: NavigationStateManager
    
    var body: some View {
        List(selection: $navigationManager.selectionState) {
                NavigationLink(value: SelectionState.changePassword) {
                    Label("Change Password", systemImage: "lock")
                }
                
                NavigationLink(value: SelectionState.twoStepVerification) {
                    Label("Two-step Verification", systemImage: "shield.checkerboard")
                }
                
                NavigationLink(value: SelectionState.biometricAuth) {
                    Label("Biometric Authentication", systemImage: "faceid")
                }
        }
        .listStyle(.sidebar)
    }
}
