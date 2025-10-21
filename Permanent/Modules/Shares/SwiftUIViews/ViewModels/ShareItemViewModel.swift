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
        case .oneDay: return Image(systemName: "clock")
        case .oneMonth: return Image(systemName: "calendar")
        case .oneYear: return Image(systemName: "calendar.badge.clock")
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
    @Published var searchText = ""
    @Published var selectedExpiration: ShareExpirationOption = .none
    @Published var showCopyNotification = false
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
    
    // Properties for archives with access
    @Published var sharedArchives: [ShareVOData] = []
    @Published var isLoadingArchives = false
    
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
        fetchSharedArchives()
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
                            
                            // Try to get V2 data for existing share links to get access level info
                            if option == .retrieve {
                                self.tryLoadV2DataForExistingLink()
                            }
                            
                            if option == .create {
                                self.navigationDirection = .forward
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
        } else {
            selectedAccessLevel = .anyoneCanView
            originalAccessLevel = .anyoneCanView
        }
        
        // Also set the permissions level (access role) from V2 data
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
        case "manager": return .manager
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
                            self.errorMessage = error
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
            let permissionsLevel = mapAccessRoleToPermissionsLevel(selectedAccessRole)
            let accessRestrictions = mapAccessLevelToAccessRestrictions(selectedAccessLevel)
            
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
                            self.errorMessage = error
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
                                }
                            }
                        }
                    }
                }
            }
        }
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
        case .curator: return "editor" // Map curator to editor since it's not in V2 API
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
                        // If V2 data is not available, we keep the default UI state
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
                        // If V2 data is not available, we keep the default UI state
                    }
                }
            }
        }
    }
    
    // MARK: - Fetch Shared Archives
    private func fetchSharedArchives() {
        guard fileModel.folderLinkId > 0,
              fileModel.parentFolderLinkId > 0 else {
            return
        }
        
        isLoadingArchives = true
        
        let downloader = DownloadManagerGCD()
        let fileDownloadInfo = FileDownloadInfoVM(
            fileType: fileModel.type,
            folderLinkId: fileModel.folderLinkId,
            parentFolderLinkId: fileModel.parentFolderLinkId
        )
        
        downloader.getRecord(fileDownloadInfo) { [weak self] recordVO, error in
            Task {
                await MainActor.run {
                    guard let self = self else { return }
                    
                    self.isLoadingArchives = false
                    
                    if let error = error {
                        print("Error fetching record details: \(error)")
                        return
                    }
                    
                    if let recordVO = recordVO,
                       let recordData = recordVO.recordVO,
                       let shareVOs = recordData.shareVOS {
                        self.sharedArchives = shareVOs
                    }
                }
            }
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
        
        guard fileModel.folderLinkId > 0,
              fileModel.parentFolderLinkId > 0 else {
            return
        }
        
        let downloader = DownloadManagerGCD()
        let fileDownloadInfo = FileDownloadInfoVM(
            fileType: fileModel.type,
            folderLinkId: fileModel.folderLinkId,
            parentFolderLinkId: fileModel.parentFolderLinkId
        )
        
        downloader.getRecord(fileDownloadInfo) { [weak self] recordVO, error in
            Task {
                await MainActor.run {
                    guard let self = self else { return }
                    
                    if error != nil {
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
