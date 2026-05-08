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

enum ArchiveGrantSource {
    case findByEmail
    case pastShares
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
    static let didUpdateSharesNotifName = Notification.Name("ShareItemViewModel.didUpdateSharesNotifName")

    struct PendingArchiveGrant {
        let name: String
        let initials: String
        let archiveID: Int?
        let thumbnailURL: String?
        let source: ArchiveGrantSource
    }

    // MARK: - Loading & Error State

    @Published var isLoading = false
    @Published var genLinkLoading = false
    @Published var errorMessage: String?

    // MARK: - Share Link State

    @Published var shareLink: String?
    @Published var showLinkSettings = false
    @Published var isCreatingLink = false
    @Published var showRevokeAlert = false

    // MARK: - Link Settings State

    @Published var selectedExpiration: ShareExpirationOption = .none
    @Published var selectedAccessLevel: ShareViewAccessLevel = .anyoneCanView
    @Published var showGeneralAccess = false
    @Published var showRoleSelection = false
    @Published var itemPreviewEnabled = false
    @Published var autoApproveEnabled = false
    @Published var selectedAccessRole: AccessRole = .viewer
    @Published var hasUnsavedChanges = false

    // MARK: - Archive Access State

    @Published var sharedArchives: [ShareVOData] = []
    @Published var isLoadingArchives = false
    @Published var shouldShowArchivesSection = false
    @Published var approvingShareIDs: Set<Int> = []
    @Published var denyingShareIDs: Set<Int> = []
    @Published var isApprovingAll = false
    @Published var showArchiveAccessManagement = false
    @Published var selectedArchiveForEdit: ShareVOData?
    @Published var selectedRoleForArchive: AccessRole?
    @Published var showRevokeArchiveAccessAlert = false
    @Published var showDenyArchiveAccessAlert = false
    @Published var selectedArchiveForDeny: ShareVOData?
    @Published var denyArchiveName: String = ""

    // MARK: - Grant & Invite State

    @Published var showFindArchiveByEmail = false
    @Published var showSelectArchiveFromPastShares = false
    @Published var showGrantArchiveAccess = false
    @Published var showInviteAndGrantAccess = false
    @Published var pendingArchiveGrant: PendingArchiveGrant?
    @Published var selectedRoleForGrantAccess: AccessRole = .viewer
    @Published var invitationRecipientFullName = ""
    @Published var invitationRecipientEmail = ""
    @Published var selectedRoleForInviteAccess: AccessRole = .viewer
    @Published var showEmailAddressField = false
    @Published var emailAddress = ""

    // MARK: - Edit Invitation State

    @Published var showEditInvitation = false
    @Published var editingInvitation: ShareVOData?
    @Published var selectedRoleForEditInvitation: AccessRole = .viewer
    @Published var showRevokeInvitationAlert = false

    // MARK: - Notification State

    @Published var showCopyNotification = false
    @Published var showArchiveAccessNotification = false
    @Published var archiveAccessNotificationMessage = "Archive access has been updated."
    @Published var showLinkSettingsNotification = false
    @Published var showRevokeLinkNotification = false
    @Published var showApproveAllNotification = false
    @Published var approveAllNotificationMessage = ""
    @Published var approveAllNotificationIsError = false

    // MARK: - Navigation

    @Published var navigationDirection: NavigationDirection = .forward

    var insertionViewTransition: AnyTransition {
        switch navigationDirection {
        case .forward:
            return .move(edge: .trailing)
        case .backward:
            return .move(edge: .leading)
        }
    }

    lazy var revokeAction: () -> Void = { [weak self] in
        self?.performRevokeLink()
    }

    // MARK: - Internal Storage (accessible to extension files)

    let fileModel: FileModel
    let shareManagementRepository: ShareManagementRepository
    var shareVO: SharebyURLVOData?
    var shareLinkV2Data: ShareLinkV2Data?
    var correctFolderLinkId: Int?
    var recordV2ThumbnailURL: String?
    var hasLoadedArchivesOnce = false
    var cachedV2ItemId: String?
    var cachedV2ItemType: String?

    // Tracks original values to detect unsaved changes
    var originalExpiration: ShareExpirationOption = .none
    var originalAccessLevel: ShareViewAccessLevel = .anyoneCanView
    var originalItemPreview: Bool = false
    var originalAutoApprove: Bool = false
    var originalAccessRole: AccessRole = .viewer

    // Child ViewModels
    let findArchiveByEmailViewModel = ShareFindArchiveByEmailViewModel()
    let pastSharesViewModel = ShareArchivesFromPastSharesViewModel()

    // MARK: - Computed Properties

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

    // MARK: - Init

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

    // MARK: - Date & Size Formatters

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
}
