//
//  CreateNewFolderViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 02.12.2025.
//

import SwiftUI

@MainActor
class CreateNewFolderViewModel: ObservableObject {
    @Published var folderName: String = ""
    @Published var isAnimating: Bool = false
    @Published var backgroundOpacity: Double = 0
    
    var isCreateButtonEnabled: Bool {
        !folderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private let onCreateFolder: (String) -> Void
    private let onDismiss: () -> Void
    
    init(
        onCreateFolder: @escaping (String) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.onCreateFolder = onCreateFolder
        self.onDismiss = onDismiss
    }
    
    func startPresentationAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            isAnimating = true
            backgroundOpacity = 1.0
        }
    }
    
    func createFolder(name: String) {
        onCreateFolder(name)
        onDismiss()
    }
    
    func callOnDismiss() {
        onDismiss()
    }
}
