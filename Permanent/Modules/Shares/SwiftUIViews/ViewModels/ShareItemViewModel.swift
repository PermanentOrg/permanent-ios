//
//  ShareItemViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 31.07.2025.
//

import SwiftUI
import Combine
import Foundation

enum ShareExpirationOption: CaseIterable {
    case oneDay, oneMonth, oneYear, never, none
    
    var title: String {
        switch self {
        case .oneDay: return "One day"
        case .oneMonth: return "One month"
        case .oneYear: return "One year"
        case .never: return "Never"
        case .none: return ""
        }
    }
    
    var icon: Image {
        switch self {
        case .oneDay: return Image(.publishOneDay)
        case .oneMonth: return Image(.publishOneMonth)
        case .oneYear: return Image(.publishOneYear)
        case .never: return Image(.publishInfinity)
        case .none: return Image(systemName: "questionmark") // Placeholder icon for none
        }
    }
    
    var expirationDate: String? {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .oneDay:
            return calendar.date(byAdding: .day, value: 1, to: now)?.ISO8601Format()
        case .oneMonth:
            return calendar.date(byAdding: .month, value: 1, to: now)?.ISO8601Format()
        case .oneYear:
            return calendar.date(byAdding: .year, value: 1, to: now)?.ISO8601Format()
        case .never:
            return nil
        case .none:
            return nil
        }
    }
}

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
    @Published var selectedExpiration: ShareExpirationOption = .none
    @Published var showCopyNotification = false
    
    let fileModel: FileModel
    private let shareManagementRepository: ShareManagementRepository
    private var shareVO: SharebyURLVOData?
    private var shareLinkV2Data: ShareLinkV2Data?
    
    var hasShareLink: Bool {
        shareLink != nil && !shareLink!.isEmpty
    }
    
    var shouldShowCreateButton: Bool {
        !hasShareLink && !genLinkLoading && !isLoading
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
    
    private func parseExpirationDate(_ dateString: String) -> Date? {
        let formatters = [
            // Format with Z (UTC timezone) - e.g., "2025-10-09T08:35:55Z"
            { () -> DateFormatter in
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                formatter.timeZone = TimeZone(abbreviation: "UTC")
                return formatter
            }(),
            // Format with space and +00 - e.g., "2025-10-09 08:35:55+00" (initial API load)
            { () -> DateFormatter in
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
                return formatter
            }(),
            // Format with timezone offset - e.g., "2025-10-09T08:35:55+0000"
            { () -> DateFormatter in
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                return formatter
            }(),
            // Format with milliseconds and timezone offset - e.g., "2025-10-09T08:35:55.000Z"
            { () -> DateFormatter in
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
                formatter.timeZone = TimeZone(abbreviation: "UTC")
                return formatter
            }(),
            // Format with milliseconds and timezone offset - e.g., "2025-10-09T08:35:55.000+0000"
            { () -> DateFormatter in
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                return formatter
            }()
        ]
        
        for formatter in formatters {
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        return nil
    }
    
    var expirationDisplayText: String {
        if let expiresDT = shareVO?.expiresDT, !expiresDT.isEmpty {
            if let date = parseExpirationDate(expiresDT) {
                let displayFormatter = DateFormatter()
                displayFormatter.dateFormat = "MMMM d, yyyy"
                return "The link will expire on \(displayFormatter.string(from: date))."
            }
        }
        return "The link will never expire."
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
                            
                            // Set the correct expiration option based on existing data
                            self.setSelectedExpirationFromShareVO(result)
                            
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
    
    // MARK: - V2 API Methods
    
    func createShareLinkV2() {
        Task {
            await MainActor.run {
                self.genLinkLoading = true
                self.errorMessage = nil
                self.shareLink = nil
            }
            
            shareManagementRepository.createShareLinkV2(file: fileModel) { [weak self] result, error in
                Task {
                    await MainActor.run {
                        guard let self = self else { return }
                        
                        if let error = error {
                            self.genLinkLoading = false
                            self.errorMessage = error
                        } else if let shareData = result {
                            self.shareLinkV2Data = shareData
                            
                            self.shareManagementRepository.getShareLink(file: self.fileModel, option: .retrieve) { [weak self] v1Result, v1Error in
                                Task {
                                    await MainActor.run {
                                        guard let self = self else { return }
                                        
                                        if let v1Error = v1Error {
                                            self.genLinkLoading = false
                                            self.errorMessage = v1Error
                                        } else if let v1ShareData = v1Result, let shareURL = v1ShareData.shareURL {
                                            self.shareVO = v1ShareData
                                            self.shareLink = shareURL
                                            self.genLinkLoading = false
                                            self.showLinkSettings = true
                                        } else {
                                            self.genLinkLoading = false
                                            self.errorMessage = "Failed to retrieve share link URL"
                                        }
                                    }
                                }
                            }
                        } else {
                            self.genLinkLoading = false
                            self.errorMessage = "Failed to create share link: No data received"
                        }
                    }
                }
            }
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
    
    private func setSelectedExpirationFromShareVO(_ shareVO: SharebyURLVOData) {
        guard let expiresDT = shareVO.expiresDT, !expiresDT.isEmpty else {
            // No expiration date means "never" - select the never option
            selectedExpiration = .never
            return
        }
        
        // Parse the expiration date using our helper method
        guard let expirationDate = parseExpirationDate(expiresDT) else {
            // If we can't parse the date, don't select any option
            selectedExpiration = .none
            return
        }
        
        let now = Date()
        
        // Calculate the time difference in hours for more precise comparison
        let timeInterval = expirationDate.timeIntervalSince(now)
        let totalHours = timeInterval / (60 * 60) // Convert seconds to hours
        let totalDays = totalHours / 24 // Convert hours to days
        
        // Determine which expiration option matches closest based on refined ranges
        if totalDays >= 360 && totalDays <= 370 {
            // 360-370 days range
            selectedExpiration = .oneYear
        } else if totalDays >= 25 && totalDays <= 35 {
            // 25-35 days range
            selectedExpiration = .oneMonth
        } else if totalHours >= 20 && totalHours <= 28 {
            // 20-28 hours range
            selectedExpiration = .oneDay
        } else {
            // In any other case, don't select anything - no predefined option matches
            selectedExpiration = .none
        }
    }
    
    func copyLink() {
        guard let shareLink = self.shareLink else { return }

        UIPasteboard.general.string = shareLink
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showCopyNotification = true
        }
        
        // Hide notification after 2 seconds with animation
        Task {
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showCopyNotification = false
                }
            }
        }
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
    
    func updateExpiration(_ option: ShareExpirationOption) {
        selectedExpiration = option
        updateShareLink(expiresDT: option.expirationDate)
    }
}
