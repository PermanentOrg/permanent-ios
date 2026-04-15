//
//  PublishViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 04.12.2025.
//

import SwiftUI

@MainActor
class PublishViewModel: ObservableObject {
    @Published var isAnimating: Bool = false
    @Published var backgroundOpacity: Double = 0
    @Published var isHighResThumbnailLoaded: Bool = false
    
    let fileName: String
    let isFolder: Bool
    let thumbnailURL: String?
    let thumbnailURL2000: String?
    
    var title: String {
        isFolder ? "Publish folder" : "Publish file"
    }
    
    private let onPublish: () -> Void
    private let onDismiss: () -> Void
    
    init(
        fileName: String,
        isFolder: Bool,
        thumbnailURL: String? = nil,
        thumbnailURL2000: String? = nil,
        onPublish: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.fileName = fileName
        self.isFolder = isFolder
        self.thumbnailURL = thumbnailURL
        self.thumbnailURL2000 = thumbnailURL2000
        self.onPublish = onPublish
        self.onDismiss = onDismiss
    }
    
    func startPresentationAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            isAnimating = true
            backgroundOpacity = 1.0
        }
    }
    
    func publish() {
        onPublish()
    }
    
    func callOnDismiss() {
        onDismiss()
    }
}
