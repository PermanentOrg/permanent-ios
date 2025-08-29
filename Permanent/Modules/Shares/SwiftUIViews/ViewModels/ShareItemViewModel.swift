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
    @Published var isLoading = false
    @Published var genLinkLoading = false
    @Published var shareLink: String?
    @Published var errorMessage: String?
    @Published var showLinkSettings = false
    @Published var isCreatingLink = false
    @Published var showEmailAddressField = false
    @Published var emailAddress = ""
    @Published var searchText = ""
    
    let fileModel: FileModel
    private let shareManagementRepository: ShareManagementRepository
    private var shareVO: SharebyURLVOData?
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
    
    init(fileModel: FileModel, shareManagementRepository: ShareManagementRepository = ShareManagementRepository()) {
        self.fileModel = fileModel
        self.shareManagementRepository = shareManagementRepository
        loadInitialData()
    }
    
    private func loadInitialData() {
        isLoading = true
        errorMessage = nil
        
        getShareLink(option: .retrieve)
    }
    
    private func getShareLink(option: ShareLinkOption) {
        Task {
            await MainActor.run {
                if option == .create {
                    genLinkLoading = true
                } else {
                    isLoading = true
                }
                errorMessage = nil
            }
            
            shareManagementRepository.getShareLink(file: fileModel, option: option) { [weak self] result, error in
                Task {
                    await MainActor.run {
                        guard let self = self else { return }
                        
                        self.isLoading = false
                        
                        if let error = error {
                            // End genLinkLoading on error
                            if option == .create {
                                self.genLinkLoading = false
                            }
                            
                            if option == .retrieve {
                                self.shareLink = nil
                            } else {
                                self.errorMessage = error
                            }
                        } else if let result = result {
                            self.shareVO = result
                            self.shareLink = result.shareURL
                            
                            if option == .create {
                                self.showLinkSettings = true
                                self.setDefaultShareSettings()
                            }
                        }
                    }
                }
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
    
    func createShareLink() {
        Task {
            getShareLink(option: .create)
        }
    }
    
    private func setDefaultShareSettings() {
        guard let shareVO = self.shareVO else { return }
        
        let manageLinkData = ManageLinkData(
            previewToggle: 1,
            autoApproveToggle: 1,
            expiresDT: shareVO.expiresDT,
            maxUses: shareVO.maxUses,
            defaultAccessRole: .viewer
        )
        
        Task {
            await MainActor.run {
                // Keep using genLinkLoading during link creation flow
                self.errorMessage = nil
            }
            
            shareManagementRepository.updateLink(model: manageLinkData, shareVO: shareVO) { [weak self] shareData, error in
                Task {
                    await MainActor.run {
                        guard let self = self else { return }
                        
                        if let error = error {
                            self.errorMessage = error
                            self.genLinkLoading = false
                        } else if let shareData = shareData {
                            self.shareVO = shareData
                            self.shareLink = shareData.shareURL
                            self.genLinkLoading = false
                        } else {
                            self.genLinkLoading = false
                        }
                    }
                }
            }
        }
    }
    
    func copyLink() {
        guard let shareLink = self.shareLink else { return }

        UIPasteboard.general.string = shareLink
    }
    
    func revokeLink() {
        guard let shareVO = self.shareVO else { return }
        
        Task {
            await MainActor.run {
                self.isLoading = true
                self.errorMessage = nil
            }
            
            shareManagementRepository.revokeLink(shareVO: shareVO) { [weak self] result in
                Task {
                    await MainActor.run {
                        guard let self = self else { return }
                        
                        self.isLoading = false
                        
                        switch result {
                        case .success:
                            self.shareLink = nil
                            self.shareVO = nil
                            self.showLinkSettings = false
                        case .error(let message):
                            self.errorMessage = message
                        }
                    }
                }
            }
        }
    }
    
    func updateShareLink(previewToggle: Bool? = nil, autoApproveToggle: Bool? = nil, expiresDT: String? = nil, maxUses: Int? = nil) {
        guard let shareVO = self.shareVO else { return }
        
        let manageLinkData = ManageLinkData(
            previewToggle: previewToggle != nil ? (previewToggle! ? 1 : 0) : shareVO.previewToggle,
            autoApproveToggle: autoApproveToggle != nil ? (autoApproveToggle! ? 1 : 0) : shareVO.autoApproveToggle,
            expiresDT: expiresDT ?? shareVO.expiresDT,
            maxUses: maxUses ?? shareVO.maxUses,
            defaultAccessRole: .viewer
        )
        
        Task {
            await MainActor.run {
                self.isLoading = true
                self.errorMessage = nil
            }
            
            shareManagementRepository.updateLink(model: manageLinkData, shareVO: shareVO) { [weak self] shareData, error in
                Task {
                    await MainActor.run {
                        guard let self = self else { return }
                        
                        self.isLoading = false
                        
                        if let error = error {
                            self.errorMessage = error
                        } else if let shareData = shareData {
                            self.shareVO = shareData
                            self.shareLink = shareData.shareURL
                        }
                    }
                }
            }
        }
    }
    
    func sendEmailInvitation() {
        Task {
            await MainActor.run {
                self.showEmailAddressField = true
            }
        }
    }
    
    func submitEmailInvitation() {
        guard !self.emailAddress.isEmpty else { return }
        
        Task {
            await MainActor.run {
                self.showEmailAddressField = false
                self.emailAddress = ""
            }
        }
    }
}
