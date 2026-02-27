//
//  ShareItemViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 31.07.2025.
//

import SwiftUI
import Combine
import Foundation

enum NavigationDirection {
    case forward
    case backward
}

enum ShareViewAccessLevel: CaseIterable {
    case anyoneCanView
    case restricted
    
    var title: String {
        switch self {
        case .anyoneCanView: return "Anyone can view"
        case .restricted: return "Restricted"
        }
    }
    
    var description: String {
        switch self {
        case .anyoneCanView: return "Anyone with the link can view and download."
        case .restricted: return "The user must have an account and be logged in to view."
        }
    }
    
    var icon: Image {
        switch self {
        case .anyoneCanView: return Image(.publishGlobe)
        case .restricted: return Image(.publishLock)
        }
    }
    
    var iconColor: Color {
        return Color.success500
    }
}

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
        case .never: return Image(systemName: "infinity")
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
    @Published var selectedExpiration: ShareExpirationOption = .none
    @Published var showCopyNotification = false
    @Published var showArchiveAccessNotification = false
    @Published var showLinkSettingsNotification = false
    @Published var showRevokeLinkNotification = false
    @Published var hasUnsavedChanges = false
    @Published var selectedAccessLevel: ShareViewAccessLevel = .anyoneCanView
    @Published var showGeneralAccess = false
    
    // New properties for restricted mode
    @Published var showRoleSelection = false
    @Published var itemPreviewEnabled = false
    @Published var autoApproveEnabled = false
    @Published var selectedAccessRole: AccessRole = .viewer
    
    // Archive access management
    @Published var showArchiveAccessManagement = false
    @Published var selectedArchiveForEdit: ShareVOData?
    @Published var selectedRoleForArchive: AccessRole?
    @Published var showFindArchiveByEmail = false
    @Published var showSelectArchiveFromPastShares = false
    
    // Properties for archives with access
    @Published var sharedArchives: [ShareVOData] = []
    @Published var isLoadingArchives = false
    @Published var shouldShowArchivesSection = false
    private var hasLoadedArchivesOnce = false
    
    // Loading states for approve/deny actions
    @Published var approvingShareIDs: Set<Int> = []
    @Published var denyingShareIDs: Set<Int> = []
    
    // Bottom alert for revoke confirmation
    @Published var showRevokeAlert = false
    
    // Bottom alert for archive access revoke confirmation
    @Published var showRevokeArchiveAccessAlert = false
    
    // Bottom alert for deny pending archive access confirmation
    @Published var showDenyArchiveAccessAlert = false
    @Published var selectedArchiveForDeny: ShareVOData?
    @Published var denyArchiveName: String = ""
    
    lazy var revokeAction: () -> Void = { [weak self] in
        self?.performRevokeLink()
    }
    
    @Published var navigationDirection: NavigationDirection = .forward
    
    // Transition control similar to AuthenticatorContainerView
    var insertionViewTransition: AnyTransition {
        switch navigationDirection {
        case .forward:
            return .move(edge: .trailing)
        case .backward:
            return .move(edge: .leading)
        }
    }
    
    // Track original values to detect changes
    private var originalExpiration: ShareExpirationOption = .none
    private var originalAccessLevel: ShareViewAccessLevel = .anyoneCanView
    private var originalItemPreview: Bool = false
    private var originalAutoApprove: Bool = false
    private var originalAccessRole: AccessRole = .viewer
    
    let fileModel: FileModel
    private let shareManagementRepository: ShareManagementRepository
    private var shareVO: SharebyURLVOData?
    private var shareLinkV2Data: ShareLinkV2Data?
    private var correctFolderLinkId: Int?
    private var recordV2ThumbnailURL: String?
    
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
        // Use V2 record thumbnail if available, otherwise use fileModel
        if let v2Data = shareLinkV2Data, v2Data.itemType == "record",
           let recordThumb = recordV2ThumbnailURL {
            return recordThumb
        }
        return fileModel.thumbnailURL500
    }
    
    var isFolder: Bool {
        // V2 data is authoritative - check it first
        if let v2Data = shareLinkV2Data, let itemType = v2Data.itemType {
            return itemType == "folder"
        }
        // Fallback to fileModel
        return fileModel.type.isFolder
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
        // Show selected expiration if it has a date (not "never" or "none")
        if selectedExpiration != .never && selectedExpiration != .none,
           let expirationDateString = selectedExpiration.expirationDate,
           !expirationDateString.isEmpty {
            if let date = parseExpirationDate(expirationDateString) {
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
        // Don't fetch shared archives yet - wait for V2 data to load first
        // fetchSharedArchives() will be called from tryLoadV2DataForExistingLink()
    }
    
    func refreshData() {
        // Only refresh archives if they've already been loaded once
        // This prevents double-loading on initial view appearance
        if hasLoadedArchivesOnce {
            fetchSharedArchives()
        }
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
                        
                        if let error = error {
                            // End loading states on error
                            self.isLoading = false
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
                            
                            // For records, extract the correct folder_linkId from recordData
                            if !self.isFolder,
                               let recordData = result.recordData,
                               let folderLinkIdInt = recordData.folderLinkID {
                                self.correctFolderLinkId = folderLinkIdInt
                            }
                            
                            // Set the correct expiration option based on existing data
                            self.setSelectedExpirationFromShareVO(result)
                            
                            // Start loading archives before ending share link loading for seamless transition
                            self.isLoadingArchives = true
                            self.isLoading = false
                            
                            // Try to get V2 data for existing share links to get access level info
                            if option == .retrieve {
                                self.tryLoadV2DataForExistingLink()
                            } else {
                                // For create option, always fetch archives
                                self.fetchSharedArchives()
                            }
                            
                            if option == .create {
                                self.navigationDirection = .forward
                                self.showLinkSettings = true
                                self.setDefaultShareSettings()
                            }
                        } else {
                            // Handle case where both result and error are nil (e.g., retrieve with no existing link)
                            self.isLoading = false
                            if option == .create {
                                self.genLinkLoading = false
                            }
                            
                            if option == .retrieve {
                                self.shareLink = nil
                                // For retrieve with no link, we still want to load archives for UI
                                self.isLoadingArchives = true
                                self.fetchSharedArchives()
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
                            
                            // Set UI state from V2 data immediately
                            self.setAccessLevelFromV2Data(shareData)
                            
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
                                            self.navigationDirection = .forward
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
        // Set expiration
        guard let expiresDT = shareVO.expiresDT, !expiresDT.isEmpty else {
            // No expiration date means "never" - select the never option
            selectedExpiration = .never
            originalExpiration = .never
            setInitialAccessLevel(shareVO)
            return
        }
        
        // Parse the expiration date using our helper method
        guard let expirationDate = parseExpirationDate(expiresDT) else {
            // If we can't parse the date, don't select any option
            selectedExpiration = .none
            originalExpiration = .none
            setInitialAccessLevel(shareVO)
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
            originalExpiration = .oneYear
        } else if totalDays >= 25 && totalDays <= 35 {
            // 25-35 days range
            selectedExpiration = .oneMonth
            originalExpiration = .oneMonth
        } else if totalHours >= 20 && totalHours <= 28 {
            // 20-28 hours range
            selectedExpiration = .oneDay
            originalExpiration = .oneDay
        } else {
            // In any other case, don't select anything - no predefined option matches
            selectedExpiration = .none
            originalExpiration = .none
        }
        
        setInitialAccessLevel(shareVO)
    }
    
    private func setInitialAccessLevel(_ shareVO: SharebyURLVOData) {
        // Check if we have V2 data available to read access restrictions from
        if let v2Data = shareLinkV2Data {
            setAccessLevelFromV2Data(v2Data)
        } else {
            // For V1 data, default to anyoneCanView since we don't have access level info from V1 API
            selectedAccessLevel = .anyoneCanView
            originalAccessLevel = .anyoneCanView
        }
    }
    
    private func setAccessLevelFromV2Data(_ v2Data: ShareLinkV2Data) {
        // Map V2 accessRestrictions to UI access level
        if let accessRestrictions = v2Data.accessRestrictions {
            let accessLevel = mapAccessRestrictionsToAccessLevel(accessRestrictions)
            selectedAccessLevel = accessLevel
            originalAccessLevel = accessLevel
            
            // API constraint: when accessRestrictions is "none", permissionsLevel must be "viewer"
            if accessRestrictions == "none" {
                selectedAccessRole = .viewer
                originalAccessRole = .viewer
                return
            }
        } else {
            selectedAccessLevel = .anyoneCanView
            originalAccessLevel = .anyoneCanView
            selectedAccessRole = .viewer
            originalAccessRole = .viewer
            return
        }
        
        // Also set the permissions level (access role) from V2 data (for restricted mode)
        if let permissionsLevel = v2Data.permissionsLevel {
            let accessRole = mapPermissionsLevelToAccessRole(permissionsLevel)
            selectedAccessRole = accessRole
            originalAccessRole = accessRole
        }
    }
    
    private func mapAccessRestrictionsToAccessLevel(_ accessRestrictions: String) -> ShareViewAccessLevel {
        switch accessRestrictions {
        case "none": return .anyoneCanView
        case "account": return .restricted
        case "approval": return .restricted // Map approval to restricted for now
        default: return .anyoneCanView
        }
    }
    
    private func mapPermissionsLevelToAccessRole(_ permissionsLevel: String) -> AccessRole {
        switch permissionsLevel {
        case "viewer": return .viewer
        case "contributor": return .contributor
        case "editor": return .editor
        case "manager": return .curator // Backend uses manager, UI shows curator
        case "owner": return .owner
        default: return .viewer
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
        
        // Track copy link event for analytics (matching UIKit version)
        trackCopyLinkEvent()
    }
    
    func showArchiveAccessUpdatedNotification() {
        // Delay showing the notification to allow view transition to complete
        Task {
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds delay
            await MainActor.run {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showArchiveAccessNotification = true
                }
            }
            
            // Hide notification after 2 seconds with animation
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showArchiveAccessNotification = false
                }
            }
        }
    }
    
    func showLinkSettingsUpdatedNotification() {
        // Delay showing the notification to allow view transition to complete
        Task {
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds delay
            await MainActor.run {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showLinkSettingsNotification = true
                }
            }
            
            // Hide notification after 2 seconds with animation
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showLinkSettingsNotification = false
                }
            }
        }
    }
    
    func showRevokeLinkSuccessNotification() {
        Task {
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds delay
            await MainActor.run {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showRevokeLinkNotification = true
                }
            }
            
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showRevokeLinkNotification = false
                }
            }
        }
    }
    
    private func trackCopyLinkEvent() {
        guard let accountId = AuthenticationManager.shared.session?.account.accountID,
              let payload = EventsPayloadBuilder.build(accountId: accountId,
                                                       eventAction: AccountEventAction.copyShareLink,
                                                       entityId: String(accountId)) else { 
            return 
        }
        
        let updateAccountOperation = APIOperation(EventsEndpoint.sendEvent(eventsPayload: payload))
        updateAccountOperation.execute(in: APIRequestDispatcher()) { _ in
        }
    }
    
    func revokeLink() {
        showRevokeAlert = true
    }
    
    func performRevokeLink() {
        guard let shareVO = self.shareVO else { return }
        
        Task {
            await MainActor.run {
                self.isLoading = true
                self.errorMessage = nil
            }
            
            if let shareLinkV2Data = self.shareLinkV2Data, let shareLinkId = shareLinkV2Data.id {
                // Use V2 delete API
                shareManagementRepository.deleteShareLinkV2(shareLinkId: shareLinkId) { [weak self] result in
                    Task {
                        await MainActor.run {
                            guard let self = self else { return }
                            
                            self.isLoading = false
                            
                            switch result {
                            case .success:
                                self.shareLink = nil
                                self.shareVO = nil
                                self.shareLinkV2Data = nil
                                self.navigationDirection = .backward
                                self.showLinkSettings = false
                                self.showRevokeLinkSuccessNotification()
                            case .error(let message):
                                self.errorMessage = message
                            }
                        }
                    }
                }
            } else if let sharebyURLID = shareVO.sharebyURLID {
                // Try V2 API using sharebyURLID as shareLinkId 
                shareManagementRepository.deleteShareLinkV2(shareLinkId: String(sharebyURLID)) { [weak self] result in
                    Task {
                        await MainActor.run {
                            guard let self = self else { return }
                            
                            self.isLoading = false
                            
                            switch result {
                            case .success:
                                self.shareLink = nil
                                self.shareVO = nil
                                self.shareLinkV2Data = nil
                                self.navigationDirection = .backward
                                self.showLinkSettings = false
                                self.showRevokeLinkSuccessNotification()
                            case .error(_):
                                // If V2 API fails, fallback to V1 API
                                self.revokeLinkV1(shareVO: shareVO)
                            }
                        }
                    }
                }
            } else {
                // Fallback to V1 API
                self.revokeLinkV1(shareVO: shareVO)
            }
        }
    }
    
    private func revokeLinkV1(shareVO: SharebyURLVOData) {
        shareManagementRepository.revokeLink(shareVO: shareVO) { [weak self] result in
            Task {
                await MainActor.run {
                    guard let self = self else { return }
                    
                    self.isLoading = false
                    
                    switch result {
                    case .success:
                        self.shareLink = nil
                        self.shareVO = nil
                        self.shareLinkV2Data = nil
                        self.navigationDirection = .backward
                        self.showLinkSettings = false
                        self.showRevokeLinkSuccessNotification()
                    case .error(let message):
                        self.errorMessage = message
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
                            self.errorMessage = self.userFriendlyErrorMessage(from: error)
                        } else if let shareData = shareData {
                            self.shareVO = shareData
                            self.shareLink = shareData.shareURL
                            
                            if self.hasUnsavedChanges {
                                self.originalExpiration = self.selectedExpiration
                                self.originalAccessLevel = self.selectedAccessLevel
                                self.originalItemPreview = self.itemPreviewEnabled
                                self.originalAutoApprove = self.autoApproveEnabled
                                self.originalAccessRole = self.selectedAccessRole
                                self.hasUnsavedChanges = false

                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    self.navigationDirection = .backward
                                    self.showLinkSettings = false
                                }
                            }
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

    func openFindArchiveByEmail() {
        navigationDirection = .forward
        showSelectArchiveFromPastShares = false
        showFindArchiveByEmail = true
    }

    func closeFindArchiveByEmail() {
        navigationDirection = .backward
        showSelectArchiveFromPastShares = false
        showFindArchiveByEmail = false
    }

    func openSelectArchiveFromPastShares() {
        navigationDirection = .forward
        showFindArchiveByEmail = false
        showSelectArchiveFromPastShares = true
    }

    func closeSelectArchiveFromPastShares() {
        navigationDirection = .backward
        showFindArchiveByEmail = false
        showSelectArchiveFromPastShares = false
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
        checkForUnsavedChanges()
    }
    
    func updateAccessLevel(_ accessLevel: ShareViewAccessLevel) {
        selectedAccessLevel = accessLevel
        
        // When switching to "anyone can view", automatically set role to viewer
        // as per API requirement (accessRestrictions "none" requires permissionsLevel "viewer")
        if accessLevel == .anyoneCanView {
            selectedAccessRole = .viewer
        }
        
        checkForUnsavedChanges()
        navigationDirection = .backward
        showGeneralAccess = false
    }
    
    func updateAccessRole(_ role: AccessRole) {
        selectedAccessRole = role
        checkForUnsavedChanges()
        navigationDirection = .backward
        showRoleSelection = false
    }
    
    func toggleItemPreview() {
        itemPreviewEnabled.toggle()
        checkForUnsavedChanges()
    }
    
    func toggleAutoApprove() {
        autoApproveEnabled.toggle()
        checkForUnsavedChanges()
    }
    
    private func checkForUnsavedChanges() {
        hasUnsavedChanges = selectedExpiration != originalExpiration || 
                           selectedAccessLevel != originalAccessLevel ||
                           itemPreviewEnabled != originalItemPreview ||
                           autoApproveEnabled != originalAutoApprove ||
                           selectedAccessRole != originalAccessRole
    }
    
    func saveChanges() {
        if hasUnsavedChanges {
            // Prefer V2 API: first try V2 data, then try to extract from existing share data
            if let shareLinkV2Data = self.shareLinkV2Data, let shareLinkId = shareLinkV2Data.id {
                updateShareLinkV2(shareLinkId: shareLinkId)
            } else if let shareVO = self.shareVO, let sharebyURLID = shareVO.sharebyURLID {
                // Use sharebyURLID from existing share data for V2 API
                updateShareLinkV2(shareLinkId: String(sharebyURLID))
            } else {
                // Fallback to V1 API only if we have no way to get share link ID
                if selectedExpiration != originalExpiration {
                    updateShareLink(
                        previewToggle: itemPreviewEnabled != originalItemPreview ? itemPreviewEnabled : nil,
                        autoApproveToggle: autoApproveEnabled != originalAutoApprove ? autoApproveEnabled : nil,
                        expiresDT: selectedExpiration.expirationDate
                    )
                } else {
                    updateShareLink(
                        previewToggle: itemPreviewEnabled != originalItemPreview ? itemPreviewEnabled : nil,
                        autoApproveToggle: autoApproveEnabled != originalAutoApprove ? autoApproveEnabled : nil
                    )
                }
            }
        } else {
            navigationDirection = .backward
            showLinkSettings = false
        }
    }
    
    // MARK: - V2 Update Method
    
    func updateShareLinkV2(shareLinkId: String) {
        Task {
            await MainActor.run {
                self.isLoading = true
                self.errorMessage = nil
            }
            
            // Map UI settings to V2 API parameters
            // Always send current values to ensure at least one parameter is present (API requirement)
            let accessRestrictions = mapAccessLevelToAccessRestrictions(selectedAccessLevel)
            
            // API requirement: when accessRestrictions is "none" (anyone can view), 
            // permissionsLevel must be "viewer"
            let permissionsLevel: String
            if accessRestrictions == "none" {
                permissionsLevel = "viewer"
            } else {
                permissionsLevel = mapAccessRoleToPermissionsLevel(selectedAccessRole)
            }
            
            // Handle expiration: send actual date for set expiration, "null" string to clear expiration
            let expirationTimestamp: String? = (selectedExpiration != .never && selectedExpiration != .none) ? selectedExpiration.expirationDate : "null"
            
            shareManagementRepository.updateShareLinkV2(
                shareLinkId: shareLinkId,
                permissionsLevel: permissionsLevel,
                accessRestrictions: accessRestrictions,
                maxUses: nil, // Not currently supported in UI
                expirationTimestamp: expirationTimestamp
            ) { [weak self] result, error in
                Task {
                    await MainActor.run {
                        guard let self = self else { return }
                        
                        self.isLoading = false
                        
                        if let error = error {
                            self.errorMessage = self.userFriendlyErrorMessage(from: error)
                        } else if let updatedData = result {
                            self.shareLinkV2Data = updatedData
                            
                            // Update UI state from the updated V2 data
                            self.setAccessLevelFromV2Data(updatedData)
                            
                            if self.hasUnsavedChanges {
                                // Update the shareVO expiration date if it changed
                                if self.selectedExpiration != self.originalExpiration {
                                    self.shareVO?.expiresDT = self.selectedExpiration.expirationDate
                                }
                                
                                self.originalExpiration = self.selectedExpiration
                                self.originalAccessLevel = self.selectedAccessLevel
                                self.originalItemPreview = self.itemPreviewEnabled
                                self.originalAutoApprove = self.autoApproveEnabled
                                self.originalAccessRole = self.selectedAccessRole
                                self.hasUnsavedChanges = false

                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    self.navigationDirection = .backward
                                    self.showLinkSettings = false
                                    
                                    // Show success notification
                                    self.showLinkSettingsUpdatedNotification()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func userFriendlyErrorMessage(from error: String) -> String {
        if error.contains("APIError") || error.contains("Permanent.") {
            return "Unable to update link settings. Please try again."
        }
        
        if error.lowercased().contains("network") || error.lowercased().contains("connection") {
            return "Network connection issue. Please check your internet and try again."
        }
        
        if error.lowercased().contains("timeout") {
            return "Request timed out. Please try again."
        }
        
        if error.lowercased().contains("authentication") || error.lowercased().contains("unauthorized") {
            return "Authentication error. Please sign in again."
        }
        
        return error
    }
    
    func revertChanges() {
        selectedExpiration = originalExpiration
        selectedAccessLevel = originalAccessLevel
        selectedAccessRole = originalAccessRole
        hasUnsavedChanges = false
    }
    
    private func mapAccessRoleToPermissionsLevel(_ role: AccessRole) -> String {
        switch role {
        case .viewer: return "viewer"
        case .contributor: return "contributor"
        case .editor: return "editor"
        case .manager: return "manager"
        case .owner: return "owner"
        case .curator: return "manager" // Backend expects manager for curator role
        }
    }
    
    private func mapAccessLevelToAccessRestrictions(_ level: ShareViewAccessLevel) -> String {
        switch level {
        case .anyoneCanView: return "none"
        case .restricted: return "approval"
        // Add more mappings as needed based on ShareViewAccessLevel cases
        }
    }
    
    private func tryLoadV2DataForExistingLink() {
        // Attempt to load V2 data for existing share links to get access restrictions info
        // Use sharebyURLID if available, otherwise fall back to the file-based method
        if let shareVO = self.shareVO, let sharebyURLID = shareVO.sharebyURLID {
            shareManagementRepository.getShareLinkV2(shareLinkId: String(sharebyURLID)) { [weak self] v2Data, error in
                Task {
                    await MainActor.run {
                        guard let self = self else { return }
                        
                        if let v2Data = v2Data {
                            self.shareLinkV2Data = v2Data
                            self.setAccessLevelFromV2Data(v2Data)
                        }
                        // Fetch shared archives after V2 data is loaded
                        self.fetchSharedArchives()
                    }
                }
            }
        } else {
            // Fallback to the file-based method (which currently returns nil)
            shareManagementRepository.getShareLinkV2(file: fileModel) { [weak self] v2Data, error in
                Task {
                    await MainActor.run {
                        guard let self = self else { return }
                        
                        if let v2Data = v2Data {
                            self.shareLinkV2Data = v2Data
                            self.setAccessLevelFromV2Data(v2Data)
                        }
                        // Fetch shared archives after V2 data is loaded
                        self.fetchSharedArchives()
                    }
                }
            }
        }
    }
    
    // MARK: - Fetch Record Details (V2 API)
    private func fetchRecordV2(recordId: String, shareToken: String?) {
        isLoadingArchives = true
        
        let operation = APIOperation(RecordV2Endpoint.getRecordById(recordId: recordId, shareToken: shareToken))
        
        operation.execute(in: APIRequestDispatcher()) { [weak self] result in
            Task {
                await MainActor.run {
                    guard let self = self else { return }
                    
                    self.isLoadingArchives = false
                    
                    switch result {
                    case .json(let response, _):
                        guard let model: RecordV2Response = JSONHelper.decoding(
                            from: response,
                            with: RecordV2Response.decoder
                        ), let recordData = model.data else {
                            self.fetchSharedArchivesV1()
                            return
                        }
                        
                        // Store V2 thumbnail for display
                        self.recordV2ThumbnailURL = recordData.thumbUrl500 ?? recordData.thumbnailUrls?.url500
                        
                        // Update folderLinkId from V2 response if available
                        if let folderLinkIdString = recordData.folderLinkId,
                           let folderLinkIdInt = Int(folderLinkIdString) {
                            self.correctFolderLinkId = folderLinkIdInt
                            
                            // Convert V2 shares to V1 format if available
                            if let sharesV2 = recordData.shares, !sharesV2.isEmpty {
                                let convertedShares = self.convertV2SharesToV1(sharesV2)
                                // Sort: pending first, then approved
                                self.sharedArchives = convertedShares.sorted { share1, share2 in
                                    let isPending1 = share1.status?.contains("pending") ?? false
                                    let isPending2 = share2.status?.contains("pending") ?? false
                                    return isPending1 && !isPending2  // Pending shares come first
                                }
                            } else {
                                // No shares means empty list
                                self.sharedArchives = []
                            }
                            // Mark as loaded and update visibility
                            self.hasLoadedArchivesOnce = true
                            self.shouldShowArchivesSection = !self.sharedArchives.isEmpty
                        } else {
                            // No folder_linkId in V2 response, fall back to V1
                            self.fetchSharedArchivesV1()
                        }
                        
                    case .error(let error, _):
                        // Fall back to V1 API
                        self.fetchSharedArchivesV1()
                        
                    default:
                        self.fetchSharedArchivesV1()
                    }
                }
            }
        }
    }
    
    // Convert V2 shares to V1 ShareVOData format
    private func convertV2SharesToV1(_ sharesV2: [RecordShareV2]) -> [ShareVOData] {
        // Get the user's own archive ID
        let userOwnArchiveId = AuthenticationManager.shared.session?.selectedArchive?.archiveID
        
        return sharesV2.compactMap { share -> ShareVOData? in
            guard let shareIdString = share.shareId,
                  let shareId = Int(shareIdString),
                  let archiveData = share.archive,
                  let archiveIdString = archiveData.archiveId,
                  let archiveId = Int(archiveIdString) else {
                return nil
            }
            
            // Skip if this share is from the user's own archive
            if let userOwnId = userOwnArchiveId, archiveId == userOwnId {
                return nil
            }
            
            // Skip if the access role is owner
            if let accessRole = share.accessRole,
               AccessRole.roleForValue(accessRole) == .owner {
                return nil
            }
            
            let folderLinkId = self.correctFolderLinkId ?? self.fileModel.folderLinkId
            let archiveVO = self.makeArchiveVO(from: archiveData)

            return ShareVOData(
                shareID: shareId,
                folderLinkID: folderLinkId > 0 ? folderLinkId : nil,
                archiveID: archiveId,
                accessRole: share.accessRole,
                type: nil,
                status: share.status,
                requestToken: nil,
                previewToggle: nil,
                folderVO: nil,
                recordVO: nil,
                archiveVO: archiveVO,
                accountVO: nil,
                createdDT: nil,
                updatedDT: nil
            )
        }
    }

    private func makeArchiveVO(from archiveData: RecordShareArchiveV2) -> ArchiveVOData? {
        guard let archiveIdString = archiveData.archiveId,
              let archiveId = Int(archiveIdString) else {
            return nil
        }

        // Build archive dictionary with all available thumbnail URLs
        var archiveDict: [String: Any] = [
            "archiveId": archiveId,
            "fullName": archiveData.name as Any
        ]
        
        // Add thumbnail URLs in priority order (use highest quality available)
        if let thumbUrl2000 = archiveData.thumbUrl2000 {
            archiveDict["thumbURL2000"] = thumbUrl2000
        }
        if let thumbUrl1000 = archiveData.thumbUrl1000 {
            archiveDict["thumbURL1000"] = thumbUrl1000
        }
        if let thumbUrl500 = archiveData.thumbUrl500 {
            archiveDict["thumbURL500"] = thumbUrl500
        }
        if let thumbUrl200 = archiveData.thumbUrl200 {
            archiveDict["thumbURL200"] = thumbUrl200
        }

        guard let jsonData = try? JSONSerialization.data(withJSONObject: archiveDict, options: []) else {
            return nil
        }

        return try? JSONDecoder().decode(ArchiveVOData.self, from: jsonData)
    }
    
    // MARK: - Fetch Shared Archives (V1 API)
    private func fetchSharedArchivesV1() {
        // Use correct folderLinkId if available, otherwise use the one from fileModel
        let folderLinkId = correctFolderLinkId ?? fileModel.folderLinkId
        
        guard folderLinkId > 0 else {
            return
        }
        
        isLoadingArchives = true
        
        let downloader = DownloadManagerGCD()
        let fileDownloadInfo = FileDownloadInfoVM(
            fileType: fileModel.type,
            folderLinkId: folderLinkId,
            parentFolderLinkId: fileModel.parentFolderLinkId
        )
        
        // Use getFolder for folders, getRecord for files
        if isFolder {
            downloader.getFolder(fileDownloadInfo) { [weak self] folderVO, error in
                Task {
                    await MainActor.run {
                        guard let self = self else { return }
                        
                        self.isLoadingArchives = false
                        
                        if let error = error {
                            // If folder API fails, it might actually be a record - try V2 record API
                            if let v2Data = self.shareLinkV2Data,
                               let itemId = v2Data.itemId,
                               let token = v2Data.token {
                                self.fetchRecordV2(recordId: itemId, shareToken: token)
                            }
                            return
                        }
                        
                        if let folderVO = folderVO,
                           let folderData = folderVO.folderVO {
                            if let shareVOs = folderData.shareVOS, !shareVOs.isEmpty {
                                // Filter out owner archives (same as V2 API)
                                let userOwnArchiveId = AuthenticationManager.shared.session?.selectedArchive?.archiveID
                                let filteredShares = shareVOs.filter { share in
                                    // Exclude if this is the user's own archive
                                    if let userOwnId = userOwnArchiveId,
                                       let shareArchiveId = share.archiveID,
                                       shareArchiveId == userOwnId {
                                        return false
                                    }
                                    // Exclude if the access role is owner
                                    if let accessRole = share.accessRole,
                                       AccessRole.roleForValue(accessRole) == .owner {
                                        return false
                                    }
                                    return true
                                }
                                
                                // Sort pending shares first, then approved shares
                                self.sharedArchives = filteredShares.sorted { share1, share2 in
                                    let isPending1 = share1.status?.contains("pending") ?? false
                                    let isPending2 = share2.status?.contains("pending") ?? false
                                    return isPending1 && !isPending2
                                }
                            } else {
                                self.sharedArchives = []
                            }
                            self.hasLoadedArchivesOnce = true
                            self.shouldShowArchivesSection = !self.sharedArchives.isEmpty
                        }
                    }
                }
            }
        } else {
            downloader.getRecord(fileDownloadInfo) { [weak self] recordVO, error in
                Task {
                    await MainActor.run {
                        guard let self = self else { return }
                        
                        self.isLoadingArchives = false
                        
                        if let error = error {
                            // If V1 record API fails, try V2 record API
                            if let v2Data = self.shareLinkV2Data,
                               let itemId = v2Data.itemId,
                               let token = v2Data.token {
                                self.fetchRecordV2(recordId: itemId, shareToken: token)
                            }
                            return
                        }
                        
                        if let recordVO = recordVO,
                           let recordData = recordVO.recordVO {
                            if let shareVOs = recordData.shareVOS, !shareVOs.isEmpty {
                                // Filter out owner archives (same as V2 API)
                                let userOwnArchiveId = AuthenticationManager.shared.session?.selectedArchive?.archiveID
                                let filteredShares = shareVOs.filter { share in
                                    // Exclude if this is the user's own archive
                                    if let userOwnId = userOwnArchiveId,
                                       let shareArchiveId = share.archiveID,
                                       shareArchiveId == userOwnId {
                                        return false
                                    }
                                    // Exclude if the access role is owner
                                    if let accessRole = share.accessRole,
                                       AccessRole.roleForValue(accessRole) == .owner {
                                        return false
                                    }
                                    return true
                                }
                                
                                // Sort pending shares first, then approved shares
                                self.sharedArchives = filteredShares.sorted { share1, share2 in
                                    let isPending1 = share1.status?.contains("pending") ?? false
                                    let isPending2 = share2.status?.contains("pending") ?? false
                                    return isPending1 && !isPending2
                                }
                            } else {
                                self.sharedArchives = []
                            }
                            self.hasLoadedArchivesOnce = true
                            self.shouldShowArchivesSection = !self.sharedArchives.isEmpty
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Fetch Shared Archives
    private func fetchSharedArchives() {
        // Check V2 data first - it's more reliable than initial fileModel type
        if let v2Data = shareLinkV2Data,
           let itemId = v2Data.itemId,
           let itemType = v2Data.itemType,
           itemType == "record" {
            // V2 data says it's a record - use V2 API to fetch by recordId
            let shareToken = v2Data.token
            fetchRecordV2(recordId: itemId, shareToken: shareToken)
        } else if !isFolder,
                  let recordData = shareVO?.recordData,
                  let folderLinkIdInt = recordData.folderLinkID {
            // Already have correct folder_linkId from share link response, use V1
            correctFolderLinkId = folderLinkIdInt
            fetchSharedArchivesV1()
        } else {
            // Use V1 API (original behavior)
            fetchSharedArchivesV1()
        }
    }
    
    // MARK: - Approve/Deny Share Requests
    
    func isApprovingShare(shareID: Int) -> Bool {
        return approvingShareIDs.contains(shareID)
    }
    
    func isDenyingShare(shareID: Int) -> Bool {
        return denyingShareIDs.contains(shareID)
    }
    
    func approveShareRequest(_ shareVO: ShareVOData, accessRole: AccessRole = .viewer) {
        guard let shareID = shareVO.shareID else { return }
        
        DispatchQueue.main.async {
            self.approvingShareIDs.insert(shareID)
            self.objectWillChange.send()
        }
        
        shareManagementRepository.approveButtonAction(shareVO: shareVO, accessRole: accessRole) { [weak self] result, updatedShareVO in
            Task {
                await MainActor.run {
                    guard let self = self else { return }
                    
                    switch result {
                    case .success:
                        if let index = self.sharedArchives.firstIndex(where: { $0.shareID == shareVO.shareID }) {
                            if let updatedShare = updatedShareVO {
                                self.fetchCompleteShareDetails(for: updatedShare, at: index, clearLoadingState: true, loadingShareID: shareID)
                            } else {
                                self.approvingShareIDs.remove(shareID)
                                self.objectWillChange.send()
                            }
                        } else {
                            self.approvingShareIDs.remove(shareID)
                            self.objectWillChange.send()
                        }
                        
                    case .error(let message):
                        self.approvingShareIDs.remove(shareID)
                        self.errorMessage = message
                        self.objectWillChange.send()
                    }
                }
            }
        }
    }
    
    func denyShareRequest(_ shareVO: ShareVOData) {
        guard let shareID = shareVO.shareID else { return }
        
        DispatchQueue.main.async {
            self.denyingShareIDs.insert(shareID)
            self.objectWillChange.send()
        }
        
        shareManagementRepository.denyButtonAction(shareVO: shareVO) { [weak self] result in
            Task {
                await MainActor.run {
                    guard let self = self else { return }
                    
                    self.denyingShareIDs.remove(shareID)
                    self.objectWillChange.send()
                    
                    switch result {
                    case .success:
                        self.sharedArchives.removeAll { $0.shareID == shareVO.shareID }
                        self.shouldShowArchivesSection = !self.sharedArchives.isEmpty
                        
                    case .error(let message):
                        self.errorMessage = message
                    }
                }
            }
        }
    }
    
    private func fetchCompleteShareDetails(for share: ShareVOData, at index: Int, clearLoadingState: Bool = false, loadingShareID: Int? = nil) {
        guard let shareID = share.shareID else {
            return
        }
        
        guard fileModel.folderLinkId > 0 else {
            return
        }
        
        let downloader = DownloadManagerGCD()
        let fileDownloadInfo = FileDownloadInfoVM(
            fileType: fileModel.type,
            folderLinkId: fileModel.folderLinkId,
            parentFolderLinkId: fileModel.parentFolderLinkId
        )
        
        // Use getFolder for folders, getRecord for files
        if isFolder {
            downloader.getFolder(fileDownloadInfo) { [weak self] folderVO, error in
                Task {
                    await MainActor.run {
                        guard let self = self else { return }
                        
                        if error != nil {
                            if clearLoadingState, let loadingID = loadingShareID {
                                self.approvingShareIDs.remove(loadingID)
                            }
                            return
                        }
                        
                        if let folderVO = folderVO,
                           let folderData = folderVO.folderVO,
                           let shareVOs = folderData.shareVOS,
                           let completeShare = shareVOs.first(where: { $0.shareID == shareID }) {
                            
                            if index < self.sharedArchives.count && self.sharedArchives[index].shareID == shareID {
                                self.sharedArchives[index] = completeShare
                            }
                        } else {
                            if index < self.sharedArchives.count && self.sharedArchives[index].shareID == shareID {
                                self.sharedArchives[index] = share
                            }
                        }
                        
                        if clearLoadingState, let loadingID = loadingShareID {
                            self.approvingShareIDs.remove(loadingID)
                        }
                        
                        self.objectWillChange.send()
                    }
                }
            }
        } else {
            downloader.getRecord(fileDownloadInfo) { [weak self] recordVO, error in
                Task {
                    await MainActor.run {
                        guard let self = self else { return }
                        
                        if error != nil {
                            if clearLoadingState, let loadingID = loadingShareID {
                                self.approvingShareIDs.remove(loadingID)
                            }
                            return
                        }
                        
                        if let recordVO = recordVO,
                           let recordData = recordVO.recordVO,
                           let shareVOs = recordData.shareVOS,
                           let completeShare = shareVOs.first(where: { $0.shareID == shareID }) {
                            
                            if index < self.sharedArchives.count && self.sharedArchives[index].shareID == shareID {
                                self.sharedArchives[index] = completeShare
                            }
                        } else {
                            if index < self.sharedArchives.count && self.sharedArchives[index].shareID == shareID {
                                self.sharedArchives[index] = share
                            }
                        }
                        
                        if clearLoadingState, let loadingID = loadingShareID {
                            self.approvingShareIDs.remove(loadingID)
                        }
                        
                        self.objectWillChange.send()
                    }
                }
            }
        }
    }
    
    // MARK: - Archive Access Management
    
    func updateArchiveAccessRole(shareVO: ShareVOData, newRole: AccessRole, completion: @escaping (RequestStatus, String?) -> Void) {
        guard shareVO.shareID != nil else {
            completion(.error(message: "Invalid share ID"), nil)
            return
        }
        
        // Set loading state
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
            self.objectWillChange.send()
        }
        
        shareManagementRepository.approveButtonAction(shareVO: shareVO, accessRole: newRole) { [weak self] result, updatedShareVO in
            Task {
                await MainActor.run {
                    guard let self = self else { return }
                    
                    self.isLoading = false
                    
                    switch result {
                    case .success:
                        // Show success notification
                        self.showArchiveAccessUpdatedNotification()
                        
                        // Update the selected archive for edit
                        if let updatedShare = updatedShareVO {
                            self.selectedArchiveForEdit?.accessRole = updatedShare.accessRole
                            
                            // Update the shared archives array
                            if let index = self.sharedArchives.firstIndex(where: { $0.shareID == shareVO.shareID }) {
                                self.sharedArchives[index].accessRole = updatedShare.accessRole
                            }
                            
                            // Reset the selected role to match the updated role
                            self.selectedRoleForArchive = AccessRole.roleForValue(updatedShare.accessRole ?? "viewer")
                            
                            completion(.success, nil)
                        } else {
                            completion(.error(message: .errorMessage), .errorMessage)
                        }
                        
                    case .error(let message):
                        self.errorMessage = message ?? .errorMessage
                        completion(.error(message: message), message)
                    }
                    
                    self.objectWillChange.send()
                }
            }
        }
    }
    
    func revokeArchiveAccess(shareVO: ShareVOData, completion: @escaping (RequestStatus, String?) -> Void) {
        guard shareVO.shareID != nil else {
            completion(.error(message: "Invalid share ID"), nil)
            return
        }
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
            self.objectWillChange.send()
        }
        
        shareManagementRepository.denyButtonAction(shareVO: shareVO) { [weak self] result in
            Task {
                await MainActor.run {
                    guard let self = self else { return }
                    
                    self.isLoading = false
                    
                    switch result {
                    case .success:
                        self.sharedArchives.removeAll { $0.shareID == shareVO.shareID }
                        
                        self.selectedArchiveForEdit = nil
                        self.selectedRoleForArchive = nil
                        
                        completion(.success, nil)
                        
                    case .error(let message):
                        self.errorMessage = message ?? .errorMessage
                        completion(.error(message: message), message)
                    }
                    
                    self.objectWillChange.send()
                }
            }
        }
    }
}
