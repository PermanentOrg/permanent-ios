//
//  RenameViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 03.12.2025.
//

import SwiftUI

@MainActor
class RenameViewModel: ObservableObject {
    @Published var itemName: String
    @Published var isAnimating: Bool = false
    @Published var backgroundOpacity: Double = 0
    
    let originalName: String
    let isFolder: Bool
    let thumbnailURL: String?
    
    var isRenameButtonEnabled: Bool {
        let trimmedName = itemName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedName.isEmpty
    }
    
    var hasNameChanged: Bool {
        let trimmedName = itemName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedName.isEmpty && trimmedName != originalName
    }
    
    var title: String {
        isFolder ? "Rename folder" : "Rename file"
    }
    
    private let onRename: (String) -> Void
    private let onDismiss: () -> Void
    
    init(
        currentName: String,
        isFolder: Bool,
        thumbnailURL: String? = nil,
        onRename: @escaping (String) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.itemName = currentName
        self.originalName = currentName
        self.isFolder = isFolder
        self.thumbnailURL = thumbnailURL
        self.onRename = onRename
        self.onDismiss = onDismiss
    }
    
    func startPresentationAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            isAnimating = true
            backgroundOpacity = 1.0
        }
    }
    
    func rename(newName: String) {
        onRename(newName)
    }
    
    func callOnDismiss() {
        onDismiss()
    }
}
