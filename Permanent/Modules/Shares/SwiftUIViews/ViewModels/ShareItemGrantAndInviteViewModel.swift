//
//  ShareItemGrantAndInviteViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 08.04.2026.
//

import SwiftUI

// Decodable response used only by submitInviteAndGrantAccess
private struct ShareInviteResponse: Decodable {
    let inviteId: Int?
}

extension ShareItemViewModel {

    // MARK: - Find Archive by Email Flow

    func openFindArchiveByEmail() {
        navigationDirection = .forward
        findArchiveByEmailViewModel.reset()
        showInviteAndGrantAccess = false
        showGrantArchiveAccess = false
        showSelectArchiveFromPastShares = false
        showFindArchiveByEmail = true
    }

    func closeFindArchiveByEmail() {
        navigationDirection = .backward
        showSelectArchiveFromPastShares = false
        showFindArchiveByEmail = false
    }

    // MARK: - Select Archive from Past Shares Flow

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

    // MARK: - Grant Archive Access Flow

    func openGrantArchiveAccess(archiveName: String, archiveInitials: String, archiveID: Int? = nil, source: ArchiveGrantSource) {
        navigationDirection = .forward
        pendingArchiveGrant = PendingArchiveGrant(name: archiveName, initials: archiveInitials, archiveID: archiveID, source: source)
        selectedRoleForGrantAccess = .viewer
        showInviteAndGrantAccess = false
        showFindArchiveByEmail = false
        showSelectArchiveFromPastShares = false
        showGrantArchiveAccess = true
    }

    func closeGrantArchiveAccess() {
        navigationDirection = .backward
        showGrantArchiveAccess = false

        switch pendingArchiveGrant?.source {
        case .findByEmail:
            showFindArchiveByEmail = true
            showSelectArchiveFromPastShares = false
        case .pastShares:
            showFindArchiveByEmail = false
            showSelectArchiveFromPastShares = true
        case .none:
            showFindArchiveByEmail = false
            showSelectArchiveFromPastShares = false
        }
    }

    func submitGrantArchiveAccess() {
        guard let pendingArchiveGrant else { return }

        let folderLinkId = correctFolderLinkId ?? fileModel.folderLinkId

        if let archiveID = pendingArchiveGrant.archiveID, folderLinkId > 0 {
            let shareRequest = ShareVOData(
                shareID: nil,
                folderLinkID: folderLinkId,
                archiveID: archiveID,
                accessRole: selectedRoleForGrantAccess.apiValue,
                type: nil,
                status: "status.generic.ok",
                requestToken: nil,
                previewToggle: nil,
                folderVO: nil,
                recordVO: nil,
                archiveVO: nil,
                accountVO: nil,
                createdDT: nil,
                updatedDT: nil
            )

            let operation = APIOperation(AccountEndpoint.updateShareRequest(shareVO: shareRequest))
            operation.execute(in: APIRequestDispatcher()) { [weak self] result in
                guard let self = self else { return }

                switch result {
                case .json(let response, _):
                    guard
                        let model: APIResults<ShareVO> = JSONHelper.decoding(
                            from: response,
                            with: APIResults<ShareVO>.decoder
                        ),
                        model.isSuccessful
                    else {
                        self.errorMessage = "Unable to grant archive access right now. Please try again."
                        return
                    }

                    self.navigationDirection = .backward
                    self.showGrantArchiveAccess = false
                    self.showInviteAndGrantAccess = false
                    self.showFindArchiveByEmail = false
                    self.showSelectArchiveFromPastShares = false
                    self.pendingArchiveGrant = nil

                    self.fetchSharedArchives()
                    self.showArchiveAccessUpdatedNotification(message: "Access granted for new archive.")

                case .error(let error, _):
                    self.errorMessage = (error as? APIError)?.message ?? "Unable to grant archive access right now. Please try again."

                default:
                    self.errorMessage = "Unable to grant archive access right now. Please try again."
                }
            }
            return
        }

        addGrantedArchiveToCurrentAccessList(
            archiveName: pendingArchiveGrant.name,
            role: selectedRoleForGrantAccess
        )

        navigationDirection = .backward
        showGrantArchiveAccess = false
        showInviteAndGrantAccess = false
        showFindArchiveByEmail = false
        showSelectArchiveFromPastShares = false
        self.pendingArchiveGrant = nil
        showArchiveAccessUpdatedNotification(message: "Access granted for new archive.")
    }

    private func addGrantedArchiveToCurrentAccessList(archiveName: String, role: AccessRole) {
        if let existingIndex = sharedArchives.firstIndex(where: { $0.archiveVO?.fullName == archiveName }) {
            sharedArchives[existingIndex].accessRole = role.apiValue
            shouldShowArchivesSection = !sharedArchives.isEmpty
            return
        }

        let archiveID = Int.random(in: 100_000...999_999)
        let shareID = -Int.random(in: 100_000...999_999)
        let now = ISO8601DateFormatter().string(from: Date())

        let localArchive = ArchiveVOData(
            childFolderVOS: nil,
            folderSizeVOS: nil,
            recordVOS: nil,
            accessRole: role.apiValue,
            fullName: archiveName,
            spaceTotal: nil,
            spaceLeft: nil,
            fileTotal: nil,
            fileLeft: nil,
            relationType: nil,
            homeCity: nil,
            homeState: nil,
            homeCountry: nil,
            itemVOS: nil,
            birthDay: nil,
            company: nil,
            archiveVODescription: nil,
            archiveID: archiveID,
            publicDT: nil,
            archiveNbr: nil,
            view: nil,
            viewProperty: nil,
            archiveVOPublic: nil,
            vaultKey: nil,
            thumbArchiveNbr: nil,
            type: nil,
            thumbStatus: .ok,
            imageRatio: nil,
            thumbURL200: nil,
            thumbURL500: nil,
            thumbURL1000: nil,
            thumbURL2000: nil,
            thumbDT: nil,
            createdDT: now,
            updatedDT: now,
            status: .ok
        )

        let localShare = ShareVOData(
            shareID: shareID,
            folderLinkID: nil,
            archiveID: archiveID,
            accessRole: role.apiValue,
            type: nil,
            status: "status.generic.ok",
            requestToken: nil,
            previewToggle: nil,
            folderVO: nil,
            recordVO: nil,
            archiveVO: localArchive,
            accountVO: nil,
            createdDT: now,
            updatedDT: now
        )

        sharedArchives.insert(localShare, at: 0)
        shouldShowArchivesSection = !sharedArchives.isEmpty
    }

    // MARK: - Invite and Grant Access Flow

    func openInviteAndGrantAccess(recipientEmail: String) {
        navigationDirection = .forward
        invitationRecipientEmail = recipientEmail
        if invitationRecipientFullName.isEmpty {
            invitationRecipientFullName = recipientEmail.split(separator: "@").first.map { String($0) } ?? ""
        }
        selectedRoleForInviteAccess = .viewer
        showGrantArchiveAccess = false
        showSelectArchiveFromPastShares = false
        showFindArchiveByEmail = false
        showInviteAndGrantAccess = true
    }

    func closeInviteAndGrantAccess() {
        navigationDirection = .backward
        showInviteAndGrantAccess = false
        showFindArchiveByEmail = true
    }

    func submitInviteAndGrantAccess() {
        let trimmedEmail = invitationRecipientEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedName = invitationRecipientFullName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty else { return }
        guard let byArchiveId = AuthenticationManager.shared.session?.selectedArchive?.archiveID else {
            errorMessage = "Unable to send invitation right now. Please try again."
            return
        }

        let folderLinkId = correctFolderLinkId ?? fileModel.folderLinkId
        guard folderLinkId > 0 else {
            errorMessage = "Unable to send invitation right now. Please try again."
            return
        }

        let folderId: Int = {
            if isFolder {
                return fileModel.folderId
            }
            if fileModel.parentFolderId > 0 {
                return fileModel.parentFolderId
            }
            return fileModel.folderId
        }()
        guard folderId > 0 else {
            errorMessage = "Unable to send invitation right now. Please try again."
            return
        }

        let operation = APIOperation(
            ShareAccessEndpoint.inviteShare(
                email: trimmedEmail,
                byArchiveId: byArchiveId,
                fullName: trimmedName,
                accessRole: selectedRoleForInviteAccess.apiValue,
                folderLinkId: folderLinkId,
                relationship: "relation.family.uncle",
                folderId: folderId
            )
        )

        operation.execute(in: APIRequestDispatcher()) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .json(let response, _):
                guard
                    let inviteResponse: ShareInviteResponse = JSONHelper.convertToModel(from: response),
                    inviteResponse.inviteId != nil
                else {
                    self.errorMessage = "Unable to send invitation right now. Please try again."
                    return
                }

                self.addInvitedRecipientToCurrentAccessList(
                    fullName: trimmedName,
                    email: trimmedEmail,
                    role: self.selectedRoleForInviteAccess
                )

                self.navigationDirection = .backward
                self.showInviteAndGrantAccess = false
                self.showFindArchiveByEmail = false
                self.showSelectArchiveFromPastShares = false
                self.showGrantArchiveAccess = false
                self.showArchiveAccessUpdatedNotification(message: "Invitation sent.")

            case .error(let error, _):
                self.errorMessage = (error as? APIError)?.message ?? "Unable to send invitation right now. Please try again."

            default:
                self.errorMessage = "Unable to send invitation right now. Please try again."
            }
        }
    }

    private func addInvitedRecipientToCurrentAccessList(fullName: String, email: String, role: AccessRole) {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else { return }

        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayName = trimmedName.isEmpty ? trimmedEmail.split(separator: "@").first.map(String.init) ?? "Invited user" : trimmedName

        if let existingIndex = sharedArchives.firstIndex(where: { $0.accountVO?.primaryEmail?.caseInsensitiveCompare(trimmedEmail) == .orderedSame }) {
            sharedArchives[existingIndex].accessRole = role.apiValue
            shouldShowArchivesSection = !sharedArchives.isEmpty
            return
        }

        let now = ISO8601DateFormatter().string(from: Date())
        let shareID = -Int.random(in: 100_000...999_999)

        let localAccount = AccountVOData(
            accountID: nil,
            primaryEmail: trimmedEmail,
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
            createdDT: now,
            updatedDT: now,
            hideChecklist: nil
        )

        let localShare = ShareVOData(
            shareID: shareID,
            folderLinkID: nil,
            archiveID: nil,
            accessRole: role.apiValue,
            type: nil,
            status: "status.generic.invited",
            requestToken: nil,
            previewToggle: nil,
            folderVO: nil,
            recordVO: nil,
            archiveVO: nil,
            accountVO: localAccount,
            createdDT: now,
            updatedDT: now
        )

        sharedArchives.append(localShare)
        shouldShowArchivesSection = !sharedArchives.isEmpty
    }

    // MARK: - Legacy Email Invitation (inline field on ShareItemView)

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

    // MARK: - Archive Access Management (Edit / Revoke)

    func updateArchiveAccessRole(shareVO: ShareVOData, newRole: AccessRole, completion: @escaping (RequestStatus, String?) -> Void) {
        guard shareVO.shareID != nil else {
            completion(.error(message: "Invalid share ID"), nil)
            return
        }

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
                        self.showArchiveAccessUpdatedNotification()

                        if let updatedShare = updatedShareVO {
                            self.selectedArchiveForEdit?.accessRole = updatedShare.accessRole

                            if let index = self.sharedArchives.firstIndex(where: { $0.shareID == shareVO.shareID }) {
                                self.sharedArchives[index].accessRole = updatedShare.accessRole
                            }

                            self.selectedRoleForArchive = AccessRole.roleForValue(updatedShare.accessRole ?? "viewer")
                            self.notifyShareUpdates()

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
                        self.notifyShareUpdates()

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

    // MARK: - Archive Access Notification

    func showArchiveAccessUpdatedNotification(message: String = "Archive access has been updated.") {
        archiveAccessNotificationMessage = message
        // Delay showing the notification to allow view transition to complete
        Task {
            try await Task.sleep(nanoseconds: 500_000_000)
            await MainActor.run {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showArchiveAccessNotification = true
                }
            }

            try await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showArchiveAccessNotification = false
                }
            }
        }
    }
}
