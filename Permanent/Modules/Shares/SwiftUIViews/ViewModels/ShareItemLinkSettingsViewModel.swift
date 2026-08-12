//
//  ShareItemLinkSettingsViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 08.04.2026.
//

import SwiftUI

extension ShareItemViewModel {

    // MARK: - Expiration Display

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
            // Format with milliseconds and UTC - e.g., "2025-10-09T08:35:55.000Z"
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
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MMMM d, yyyy"

        // With no unsaved change, show the real server expiry: recomputing from the preset drifts, and
        // reads "never" when the true expiry falls outside its ranges.
        if selectedExpiration == originalExpiration, let actualExpiryDate {
            return "The link will expire on \(displayFormatter.string(from: actualExpiryDate))."
        }

        // Otherwise the user has picked a preset that isn't saved yet — preview what it becomes.
        if selectedExpiration != .never && selectedExpiration != .none,
           let expirationDateString = selectedExpiration.expirationDate,
           !expirationDateString.isEmpty,
           let date = parseExpirationDate(expirationDateString) {
            return "The link will expire on \(displayFormatter.string(from: date))."
        }
        return "The link will never expire."
    }

    // MARK: - Initial State from API Data

    /// Sets expiration and access level state from a retrieved V1 share object.
    func setSelectedExpirationFromShareVO(_ shareVO: SharebyURLVOData) {
        guard let expiresDT = shareVO.expiresDT, !expiresDT.isEmpty else {
            // No expiration date means "never" - select the never option
            selectedExpiration = .never
            originalExpiration = .never
            actualExpiryDate = nil
            setInitialAccessLevel(shareVO)
            return
        }

        guard let expirationDate = parseExpirationDate(expiresDT) else {
            // If we can't parse the date, don't select any option
            selectedExpiration = .none
            originalExpiration = .none
            actualExpiryDate = nil
            setInitialAccessLevel(shareVO)
            return
        }

        // Store the real server expiry for display, independent of the preset mapping below
        // (so an expiry outside the preset ranges still shows its true date, not "never").
        actualExpiryDate = expirationDate

        let now = Date()
        let timeInterval = expirationDate.timeIntervalSince(now)
        let totalHours = timeInterval / (60 * 60)
        let totalDays = totalHours / 24

        if totalDays >= 360 && totalDays <= 370 {
            selectedExpiration = .oneYear
            originalExpiration = .oneYear
        } else if totalDays >= 25 && totalDays <= 35 {
            selectedExpiration = .oneMonth
            originalExpiration = .oneMonth
        } else if totalHours >= 20 && totalHours <= 28 {
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
        if let v2Data = shareLinkV2Data {
            setAccessLevelFromV2Data(v2Data)
        } else {
            // For V1 data, default to anyoneCanView since we don't have access level info from V1 API
            selectedAccessLevel = .anyoneCanView
            originalAccessLevel = .anyoneCanView
        }
    }

    /// Sets access level and role state from V2 share link data.
    func setAccessLevelFromV2Data(_ v2Data: ShareLinkV2Data) {
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

    // MARK: - Update Actions

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

    func revertChanges() {
        selectedExpiration = originalExpiration
        selectedAccessLevel = originalAccessLevel
        selectedAccessRole = originalAccessRole
        hasUnsavedChanges = false
    }

    // MARK: - Save Changes

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

    // MARK: - V1 Update

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
                                // Keep the displayed expiry in sync after saving (nil for never/none).
                                self.actualExpiryDate = self.selectedExpiration.expirationDate.flatMap(self.parseExpirationDate)
                                self.originalAccessLevel = self.selectedAccessLevel
                                self.originalItemPreview = self.itemPreviewEnabled
                                self.originalAutoApprove = self.autoApproveEnabled
                                self.originalAccessRole = self.selectedAccessRole
                                self.hasUnsavedChanges = false

                                self.fetchSharedArchives()

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

    // MARK: - V2 Update

    func updateShareLinkV2(shareLinkId: String) {
        Task {
            await MainActor.run {
                self.isLoading = true
                self.errorMessage = nil
            }

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
                            let previousData = self.shareLinkV2Data
                            let mergedData = ShareLinkV2Data(
                                id: updatedData.id ?? previousData?.id,
                                itemId: updatedData.itemId ?? previousData?.itemId,
                                itemType: updatedData.itemType ?? previousData?.itemType,
                                token: updatedData.token ?? previousData?.token,
                                permissionsLevel: updatedData.permissionsLevel ?? previousData?.permissionsLevel,
                                accessRestrictions: updatedData.accessRestrictions ?? previousData?.accessRestrictions,
                                maxUses: updatedData.maxUses ?? previousData?.maxUses,
                                usesExpended: updatedData.usesExpended ?? previousData?.usesExpended,
                                expirationTimestamp: updatedData.expirationTimestamp,
                                creatorAccount: updatedData.creatorAccount ?? previousData?.creatorAccount,
                                createdAt: updatedData.createdAt ?? previousData?.createdAt,
                                updatedAt: updatedData.updatedAt ?? previousData?.updatedAt
                            )
                            self.shareLinkV2Data = mergedData
                            self.setAccessLevelFromV2Data(mergedData)

                            if self.hasUnsavedChanges {
                                // Update the shareVO expiration date if it changed
                                if self.selectedExpiration != self.originalExpiration {
                                    self.shareVO?.expiresDT = self.selectedExpiration.expirationDate
                                }

                                self.originalExpiration = self.selectedExpiration
                                // Keep the displayed expiry in sync after saving (nil for never/none).
                                self.actualExpiryDate = self.selectedExpiration.expirationDate.flatMap(self.parseExpirationDate)
                                self.originalAccessLevel = self.selectedAccessLevel
                                self.originalItemPreview = self.itemPreviewEnabled
                                self.originalAutoApprove = self.autoApproveEnabled
                                self.originalAccessRole = self.selectedAccessRole
                                self.hasUnsavedChanges = false

                                self.fetchSharedArchives()

                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    self.navigationDirection = .backward
                                    self.showLinkSettings = false
                                    self.showLinkSettingsUpdatedNotification()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Mappers

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

    // MARK: - Error Helpers

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

    // MARK: - Link Settings Notification

    func showLinkSettingsUpdatedNotification() {
        // Delay showing the notification to allow view transition to complete
        Task {
            try await Task.sleep(nanoseconds: 500_000_000)
            await MainActor.run {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showLinkSettingsNotification = true
                }
            }

            try await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showLinkSettingsNotification = false
                }
            }
        }
    }
}
