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

    /// True only for the F1 lockout state: every invitation is already accepted (so no
    /// `.pending` row shows an "Accept" button that could enable "Next"), and there is an
    /// accepted archive to proceed with — either already current, or an `.ok` archive we can
    /// adopt. While a `.pending` invite remains we return false and leave the screen alone:
    /// the Accept button is the intended path, and auto-adopting there would silently switch
    /// the user's current archive without consent. Pure + side-effect-free (unit-testable).
    func shouldEnableNextForAcceptedArchive() -> Bool {
        guard !containerViewModel.allArchives.contains(where: { $0.status == .pending })
        else { return false }
        return AuthenticationManager.shared.session?.selectedArchive != nil
            || containerViewModel.allArchives.contains(where: { $0.status == .ok })
    }

    /// The already-accepted (`.ok`) archive to adopt as current — only when the lockout
    /// state holds AND no archive is selected yet. Nil when one is already current (nothing
    /// to change server-side; just enable "Next") or none qualifies. Pure/unit-testable.
    func archiveToAdoptOnAppear() -> ArchiveVOData? {
        guard shouldEnableNextForAcceptedArchive(),
              AuthenticationManager.shared.session?.selectedArchive == nil,
              let firstAccepted = containerViewModel.allArchives.first(where: { $0.status == .ok })
        else { return nil }

        return containerViewModel.allArchivesVO
            .first(where: { $0.archiveVO?.archiveID == firstAccepted.archiveID })?.archiveVO
    }

    /// Fixes the all-accepted onboarding lockout: when every invitation is already accepted
    /// there is no Accept button to flip `isArchiveAccepted`, so "Next" stays disabled. If a
    /// current archive is already selected (e.g. adopted on a previous appearance of this
    /// screen, which rebuilds a fresh view model), just enable "Next". Otherwise adopt the
    /// first accepted archive as current (the same server change + local update the archive
    /// switcher performs), then enable "Next" on success. No-op while a `.pending` invite
    /// remains, once accepted, or while a request is in flight.
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
