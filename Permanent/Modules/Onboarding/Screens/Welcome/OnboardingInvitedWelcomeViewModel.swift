//
//  OnboardingInvitedWelcomeViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 02.08.2024.

import Foundation

class OnboardingInvitedWelcomeViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var showAlert: Bool = false
    
    @Published var isArchiveAccepted: Bool = false
    var containerViewModel: OnboardingContainerViewModel
    
    init(containerViewModel: OnboardingContainerViewModel) {
        self.containerViewModel = containerViewModel
    }

    /// True only when every invitation is already accepted, so no Accept button exists to enable Next.
    /// False while any invite is pending, since auto-adopting would switch archives without consent.
    func shouldEnableNextForAcceptedArchive() -> Bool {
        guard !containerViewModel.allArchives.contains(where: { $0.status == .pending })
        else { return false }
        return AuthenticationManager.shared.session?.selectedArchive != nil
            || containerViewModel.allArchives.contains(where: { $0.status == .ok })
    }

    /// The accepted archive to adopt, only when the lockout state holds and none is selected yet. Nil
    /// when one is already current, where there is nothing to change server-side.
    func archiveToAdoptOnAppear() -> ArchiveVOData? {
        guard shouldEnableNextForAcceptedArchive(),
              AuthenticationManager.shared.session?.selectedArchive == nil,
              let firstAccepted = containerViewModel.allArchives.first(where: { $0.status == .ok })
        else { return nil }

        return containerViewModel.allArchivesVO
            .first(where: { $0.archiveVO?.archiveID == firstAccepted.archiveID })?.archiveVO
    }

    /// Breaks the all-accepted lockout, where no Accept button exists to enable Next: enables it when
    /// an archive is already current, otherwise adopts the first accepted one and then enables it.
    func activateExistingAcceptedArchiveIfNeeded() {
        guard !isArchiveAccepted, !isLoading, shouldEnableNextForAcceptedArchive() else { return }

        guard let archiveVOData = archiveToAdoptOnAppear() else {
            // An archive is already current — just enable "Next" (this recovers the screen
            // after the adopt already happened and the view model was recreated).
            isArchiveAccepted = true
            return
        }

        isLoading = true
        changeArchive(archiveVOData) { [weak self] success, _ in
            guard let self = self else { return }
            self.isLoading = false
            if success {
                self.isArchiveAccepted = true
            } else {
                self.showAlert = true
            }
        }
    }

    func acceptPendingArchive(archive: OnboardingArchive) {
        isLoading = true
        guard let archiveVO = containerViewModel.allArchivesVO.first(where: { $0.archiveVO?.archiveID == archive.archiveID}),
              let archiveVOData = archiveVO.archiveVO else {
            isLoading = false
            showAlert = true
            return
        }
        
        acceptArchiveOperation(archive: archiveVOData, { status, error in
            self.isLoading = false
            if status {
                self.isArchiveAccepted = true
                guard let _ = archiveVOData.archiveID else {
                    self.showAlert = true
                    return
                }

                archive.status = .ok
            } else {
                // Surface the failure — previously a failed accept just stopped the spinner
                // with no feedback and "Next" stayed disabled: a silent dead-end.
                self.showAlert = true
            }
        })
    }
    
    func acceptArchiveOperation(archive: ArchiveVOData, _ completionBlock: @escaping ((Bool, Error?) -> Void)) {
        let acceptArchiveOperation = APIOperation(ArchivesEndpoint.accept(archiveVO: archive))

        acceptArchiveOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<NoDataModel> = JSONHelper.decoding(from: response, with: APIResults<NoDataModel>.decoder),
                    model.isSuccessful
                else {
                    completionBlock(false, APIError.invalidResponse)
                    return
                }
                
                self.changeArchive(archive) { success, error in
                    if success {
                        completionBlock(true, nil)
                        return
                    } else {
                        completionBlock(false, APIError.invalidResponse)
                        return
                    }
                }
                
            case .error:
                completionBlock(false, APIError.invalidResponse)
                return
                
            default:
                completionBlock(false, APIError.invalidResponse)
                return
            }
        }
    }
    
    func changeArchive(_ archive: ArchiveVOData, _ completionBlock: @escaping ((Bool, Error?) -> Void)) {
        guard let archiveId = archive.archiveID, let archiveNbr = archive.archiveNbr else {
            completionBlock(false, APIError.unknown)
            return
        }
        
        let changeArchiveOperation = APIOperation(ArchivesEndpoint.change(archiveId: archiveId, archiveNbr: archiveNbr))
        changeArchiveOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<NoDataModel> = JSONHelper.decoding(from: response, with: APIResults<NoDataModel>.decoder),
                    model.isSuccessful
                else {
                    completionBlock(false, APIError.invalidResponse)
                    return
                }
                self.setCurrentArchive(archive)
                completionBlock(true, nil)
                return
                
            case .error:
                completionBlock(false, APIError.invalidResponse)
                return
                
            default:
                completionBlock(false, APIError.invalidResponse)
                return
            }
        }
    }
    
    func setCurrentArchive(_ archive: ArchiveVOData) {
        AuthenticationManager.shared.updateSelectedArchive(archive)
    }
    
    func trackEvents() {
        guard let accountId = AuthenticationManager.shared.session?.account.accountID,
              let payload = EventsPayloadBuilder.build(accountId: accountId,
                                                       eventAction: AccountEventAction.startOnboarding,
                                                       entityId: String(accountId)) else { return }
        let updateAccountOperation = APIOperation(EventsEndpoint.sendEvent(eventsPayload: payload))
        updateAccountOperation.execute(in: APIRequestDispatcher()) {_ in}
    }
}
