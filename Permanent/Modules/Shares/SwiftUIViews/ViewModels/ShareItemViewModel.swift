//
//  ShareItemViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 31.07.2025.
//

import SwiftUI
import Combine
import Foundation

@MainActor
class ShareItemViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var shareLink: String?
    @Published var errorMessage: String?
    @Published var showLinkSettings = false
    @Published var isCreatingLink = false
    @Published var showEmailAddressField = false
    @Published var emailAddress = ""
    @Published var searchText = ""
    
    // MARK: - File Properties
    let fileModel: FileModel
    
    // MARK: - Computed Properties
    var hasShareLink: Bool {
        shareLink != nil
    }
    
    var fileName: String {
        fileModel.name
    }
    
    var fileSize: String {
        formatFileSize(fileModel.size)
    }
    
    var fileDate: String {
        formatFileDate(fileModel.createdDT)
    }
    
    var thumbnailURL: String? {
        fileModel.thumbnailURL500
    }
    
    var isFolder: Bool {
        fileModel.type.isFolder
    }
    
    var shareDisplayData: String {
        ShareItemViewModel.formatDate(fileModel.createdDT ?? "")
    }
    
    // MARK: - Initialization
    init(fileModel: FileModel) {
        self.fileModel = fileModel
    }
    
    // MARK: - Private Methods
    private func loadInitialData() {
        isLoading = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isLoading = false
            // For demo purposes, sometimes have a link already
            if Bool.random() {
                self.shareLink = "https://permanent.org/share/example-link"
            }
        }
    }
    
    static func formatDate(_ dateString: String) -> String {
        guard !dateString.isEmpty && dateString != "-" else { return "" }
        
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "MMM. d, yyyy"
        
        if let date = inputFormatter.date(from: dateString) {
            return outputFormatter.string(from: date)
        } else {
            return dateString
        }
    }
    
    private func formatFileSize(_ size: Int64) -> String {
        guard size > 0 else { return "" }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    private func formatFileDate(_ dateString: String?) -> String {
        guard let dateString = dateString else { return "" }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM. dd, yyyy"
            return displayFormatter.string(from: date)
        }
        
        return ""
    }
    
    // MARK: - Public Methods
    func createShareLink() {
        isCreatingLink = true
        
        // Simulate link creation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.isCreatingLink = false
            self.shareLink = "https://permanent.org/share/new-link-\(UUID().uuidString.prefix(8))"
            self.showLinkSettings = true
        }
    }
    
    func copyLink() {
        guard let shareLink = shareLink else { return }
        
        // For now, just copy to clipboard
        #if os(iOS)
        UIPasteboard.general.string = shareLink
        #endif
        
        // In the real implementation, this would show the activity controller
        print("Share link copied: \(shareLink)")
    }
    
    func revokeLink() {
        // Simulate revoke
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.shareLink = nil
            self.showLinkSettings = false
        }
    }
    
    func sendEmailInvitation() {
        showEmailAddressField = true
    }
    
    func submitEmailInvitation() {
        guard !emailAddress.isEmpty else { return }
        
        // Simulate sending invitation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.showEmailAddressField = false
            self.emailAddress = ""
            // Could show success message
        }
    }
}
