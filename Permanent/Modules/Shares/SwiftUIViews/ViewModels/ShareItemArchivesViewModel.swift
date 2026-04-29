//
//  ShareItemArchivesViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 08.04.2026.
//

import Foundation

extension ShareItemViewModel {

    // MARK: - Loading State Queries

    func isApprovingShare(shareID: Int) -> Bool {
        return approvingShareIDs.contains(shareID)
    }

    func isDenyingShare(shareID: Int) -> Bool {
        return denyingShareIDs.contains(shareID)
    }

    // MARK: - Fetch Shared Archives (entry point)

    /// Fetches all archives that have access to this item.
    func fetchSharedArchives() {
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
            fetchSharedArchivesV1()
        }
    }

    // MARK: - Fetch via V2 Record API

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

                        self.recordV2ThumbnailURL = recordData.thumbUrl500 ?? recordData.thumbnailUrls?.url500

                        if let folderLinkIdString = recordData.folderLinkId,
                           let folderLinkIdInt = Int(folderLinkIdString) {
                            self.correctFolderLinkId = folderLinkIdInt

                            // Convert V2 shares to V1 format if available
                            if let sharesV2 = recordData.shares, !sharesV2.isEmpty {
                                let convertedShares = self.convertV2SharesToV1(sharesV2)
                                // Sort: pending first, then approved
                                let sortedShares = convertedShares.sorted { share1, share2 in
                                    let isPending1 = share1.status?.contains("pending") ?? false
                                    let isPending2 = share2.status?.contains("pending") ?? false
                                    return isPending1 && !isPending2
                                }
                                self.finalizeSharedArchives(sortedShares)
                            } else {
                                self.finalizeSharedArchives([])
                            }
                        } else {
                            // No folder_linkId in V2 response, fall back to V1
                            self.fetchSharedArchivesV1()
                        }

                    case .error:
                        // Fall back to V1 API
                        self.fetchSharedArchivesV1()

                    default:
                        self.fetchSharedArchivesV1()
                    }
                }
            }
        }
    }

    // MARK: - Fetch via V1 API

    private func fetchSharedArchivesV1() {
        // Use correct folderLinkId if available, otherwise use the one from fileModel
        let folderLinkId = correctFolderLinkId ?? fileModel.folderLinkId

        guard folderLinkId > 0 else {
            isLoadingArchives = false
            return
        }

        isLoadingArchives = true

        let downloader = DownloadManagerGCD()
        let fileDownloadInfo = FileDownloadInfoVM(
            fileType: fileModel.type,
            folderLinkId: folderLinkId,
            parentFolderLinkId: fileModel.parentFolderLinkId
        )

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
                                    if let userOwnId = userOwnArchiveId,
                                       let shareArchiveId = share.archiveID,
                                       shareArchiveId == userOwnId {
                                        return false
                                    }
                                    if let accessRole = share.accessRole,
                                       AccessRole.roleForValue(accessRole) == .owner {
                                        return false
                                    }
                                    return true
                                }

                                // Sort pending shares first, then approved shares
                                let sortedShares = filteredShares.sorted { share1, share2 in
                                    let isPending1 = share1.status?.contains("pending") ?? false
                                    let isPending2 = share2.status?.contains("pending") ?? false
                                    return isPending1 && !isPending2
                                }
                                self.finalizeSharedArchives(sortedShares)
                            } else {
                                self.finalizeSharedArchives([])
                            }
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
                                    if let userOwnId = userOwnArchiveId,
                                       let shareArchiveId = share.archiveID,
                                       shareArchiveId == userOwnId {
                                        return false
                                    }
                                    if let accessRole = share.accessRole,
                                       AccessRole.roleForValue(accessRole) == .owner {
                                        return false
                                    }
                                    return true
                                }

                                // Sort pending shares first, then approved shares
                                let sortedShares = filteredShares.sorted { share1, share2 in
                                    let isPending1 = share1.status?.contains("pending") ?? false
                                    let isPending2 = share2.status?.contains("pending") ?? false
                                    return isPending1 && !isPending2
                                }
                                self.finalizeSharedArchives(sortedShares)
                            } else {
                                self.finalizeSharedArchives([])
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - V2 to V1 Conversion

    private func convertV2SharesToV1(_ sharesV2: [RecordShareV2]) -> [ShareVOData] {
        let userOwnArchiveId = AuthenticationManager.shared.session?.selectedArchive?.archiveID

        return sharesV2.compactMap { share -> ShareVOData? in
            guard let shareIdString = share.shareId,
                  let shareId = Int(shareIdString),
                  let archiveData = share.archive,
                  let archiveIdString = archiveData.archiveId,
                  let archiveId = Int(archiveIdString) else {
                return nil
            }

            if let userOwnId = userOwnArchiveId, archiveId == userOwnId {
                return nil
            }

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

    // MARK: - Pending Invite Merge

    private func fetchPendingShareInvites(completion: @escaping ([ShareVOData]) -> Void) {
        let operation = APIOperation(InviteEndpoint.getMyInvites)
        operation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<InviteVO> = JSONHelper.decoding(
                        from: response,
                        with: APIResults<InviteVO>.decoder
                    ),
                    model.isSuccessful
                else {
                    completion([])
                    return
                }

                let currentArchiveId = AuthenticationManager.shared.session?.selectedArchive?.archiveID
                let invitedShares: [ShareVOData] = model.results
                    .flatMap { $0.data ?? [] }
                    .compactMap { $0.invite }
                    .filter { invite in
                        guard invite.type == "type.invite.share" else { return false }
                        guard invite.status == Constants.API.InviteStatus.pending else { return false }
                        if let currentArchiveId, let byArchiveId = invite.byArchiveID {
                            return byArchiveId == currentArchiveId
                        }
                        return true
                    }
                    .compactMap { invite in
                        let email = invite.email?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                        guard !email.isEmpty else { return nil }

                        let fullName = invite.fullName?.trimmingCharacters(in: .whitespacesAndNewlines)
                        let displayName = (fullName?.isEmpty == false) ? fullName! : email.split(separator: "@").first.map(String.init) ?? "Invited user"

                        let account = AccountVOData(
                            accountID: nil,
                            primaryEmail: email,
                            fullName: displayName,
                            address: nil,
                            address2: nil,
                            country: nil,
                            city: nil,
                            state: nil,
                            zip: nil,
                            primaryPhone: nil,
                            defaultArchiveID: nil,
                            level: nil,
                            apiToken: nil,
                            betaParticipant: nil,
                            facebookAccountID: nil,
                            googleAccountID: nil,
                            status: nil,
                            type: nil,
                            emailStatus: nil,
                            phoneStatus: nil,
                            notificationPreferences: nil,
                            agreed: nil,
                            optIn: nil,
                            emailArray: nil,
                            inviteCode: nil,
                            rememberMe: nil,
                            keepLoggedIn: nil,
                            accessRole: nil,
                            spaceTotal: nil,
                            spaceLeft: nil,
                            fileTotal: nil,
                            fileLeft: nil,
                            changePrimaryEmail: nil,
                            changePrimaryPhone: nil,
                            createdDT: invite.createdDT,
                            updatedDT: invite.updatedDT,
                            hideChecklist: nil
                        )

                        return ShareVOData(
                            shareID: (invite.inviteID ?? -1) * -1,
                            folderLinkID: nil,
                            archiveID: nil,
                            accessRole: invite.accessRole,
                            type: invite.type,
                            status: "status.generic.invited",
                            requestToken: invite.token,
                            previewToggle: nil,
                            folderVO: nil,
                            recordVO: nil,
                            archiveVO: nil,
                            accountVO: account,
                            createdDT: invite.createdDT,
                            updatedDT: invite.updatedDT
                        )
                    }

                completion(invitedShares)

            case .error:
                completion([])

            default:
                completion([])
            }
        }
    }

    private func finalizeSharedArchives(_ baseShares: [ShareVOData]) {
        fetchPendingShareInvites { [weak self] invitedShares in
            guard let self = self else { return }

            var mergedShares = baseShares
            for invitedShare in invitedShares {
                let invitedEmail = invitedShare.accountVO?.primaryEmail?.lowercased()
                let alreadyExists = mergedShares.contains { existing in
                    guard let invitedEmail else { return false }
                    return existing.accountVO?.primaryEmail?.lowercased() == invitedEmail
                }
                if !alreadyExists {
                    mergedShares.append(invitedShare)
                }
            }

            self.sharedArchives = mergedShares
            self.hasLoadedArchivesOnce = true
            self.shouldShowArchivesSection = !self.sharedArchives.isEmpty
        }
    }

    // MARK: - Approve / Deny Share Requests

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
                        self.notifyShareUpdates()

                    case .error(let message):
                        self.errorMessage = message
                    }
                }
            }
        }
    }

    // MARK: - Fetch Complete Share Details (post-approve enrichment)

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

                        self.notifyShareUpdates()
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

                        self.notifyShareUpdates()
                        self.objectWillChange.send()
                    }
                }
            }
        }
    }

    // MARK: - Pending Shares

    var pendingShares: [ShareVOData] {
        sharedArchives.filter { $0.status?.contains("pending") == true }
    }

    // MARK: - Approve All Pending Requests

    func approveAllPendingRequests() {
        let pending = pendingShares
        guard !pending.isEmpty else { return }

        isApprovingAll = true

        // Approve one by one sequentially using a recursive helper
        approveNextPending(remaining: pending, hadError: false)
    }

    private func approveNextPending(remaining: [ShareVOData], hadError: Bool) {
        guard let next = remaining.first else {
            // All done
            isApprovingAll = false
            showApproveAllNotification(hadError: hadError)
            return
        }

        guard let shareID = next.shareID else {
            // Skip invalid entry, move to next
            approveNextPending(remaining: Array(remaining.dropFirst()), hadError: hadError)
            return
        }

        approvingShareIDs.insert(shareID)
        objectWillChange.send()

        shareManagementRepository.approveButtonAction(shareVO: next, accessRole: .viewer) { [weak self] result, updatedShareVO in
            Task {
                await MainActor.run {
                    guard let self = self else { return }

                    var errorOccurred = hadError

                    switch result {
                    case .success:
                        if let index = self.sharedArchives.firstIndex(where: { $0.shareID == next.shareID }) {
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

                    case .error:
                        self.approvingShareIDs.remove(shareID)
                        self.objectWillChange.send()
                        errorOccurred = true
                    }

                    // Continue with next pending request
                    self.approveNextPending(remaining: Array(remaining.dropFirst()), hadError: errorOccurred)
                }
            }
        }
    }

    private func showApproveAllNotification(hadError: Bool) {
        approveAllNotificationIsError = hadError
        approveAllNotificationMessage = hadError
            ? "Some of the requests were not accepted."
            : "All requests have been accepted."

        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            await MainActor.run {
                showApproveAllNotification = true
            }

            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                showApproveAllNotification = false
            }
        }
    }

    // MARK: - Notify Share Updates

    /// Posts a notification with the updated file model so UIKit consumers can refresh.
    func notifyShareUpdates() {
        var updatedFileModel = fileModel
        updatedFileModel.minArchiveVOS = sharedArchives.compactMap { share in
            guard let archiveID = share.archiveID,
                  let shareID = share.shareID else {
                return nil
            }

            return MinArchiveVO(
                name: share.archiveVO?.fullName ?? "",
                thumbnail: share.archiveVO?.thumbURL200,
                shareStatus: share.status ?? "",
                shareId: shareID,
                archiveID: archiveID,
                folderLinkID: share.folderLinkID,
                accessRole: share.accessRole
            )
        }

        NotificationCenter.default.post(
            name: Self.didUpdateSharesNotifName,
            object: self,
            userInfo: ["fileModel": updatedFileModel]
        )
    }
}
