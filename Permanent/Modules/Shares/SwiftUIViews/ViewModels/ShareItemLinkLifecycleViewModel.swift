//
//  ShareItemLinkLifecycleViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 08.04.2026.
//

import SwiftUI
import Foundation

extension ShareItemViewModel {

    // MARK: - Load / Retrieve

    func getShareLink(option: ShareLinkOption) {
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

                            self.setSelectedExpirationFromShareVO(result)

                            // Start loading archives before ending share link loading for seamless transition
                            self.isLoadingArchives = true
                            self.isLoading = false

                            // Try to get V2 data for existing share links to get access level info
                            if option == .retrieve {
                                self.tryLoadV2DataForExistingLink()
                            } else {
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

    // MARK: - Create

    func createShareLink() {
        Task {
            getShareLink(option: .create)
        }
    }

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
                                            self.fetchSharedArchives()
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

    // MARK: - Default Settings (called after V1 create)

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

    // MARK: - Revoke

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
                                self.fetchSharedArchives()
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
                                self.fetchSharedArchives()
                            case .error:
                                // If V2 API fails, fallback to V1 API
                                self.revokeLinkV1(shareVO: shareVO)
                            }
                        }
                    }
                }
            } else {
                // Fallback to V1 API
                revokeLinkV1(shareVO: shareVO)
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
                        self.fetchSharedArchives()
                    case .error(let message):
                        self.errorMessage = message
                    }
                }
            }
        }
    }

    // MARK: - V2 Load for Existing Links

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
                        self.fetchSharedArchives()
                    }
                }
            }
        }
    }

    // MARK: - Copy Link

    func copyLink() {
        guard let shareLink = self.shareLink else { return }

        UIPasteboard.general.string = shareLink

        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showCopyNotification = true
        }

        Task {
            try await Task.sleep(nanoseconds: 2_000_000_000)
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

    // MARK: - Revoke Notification

    func showRevokeLinkSuccessNotification() {
        Task {
            try await Task.sleep(nanoseconds: 500_000_000)
            await MainActor.run {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showRevokeLinkNotification = true
                }
            }

            try await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showRevokeLinkNotification = false
                }
            }
        }
    }
}
