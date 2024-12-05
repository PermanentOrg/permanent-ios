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
        AuthenticationManager.shared.session?.selectedArchive = archive
    }
    
    func trackEvents() {
        guard let accountId = AuthenticationManager.shared.session?.account.accountID,
              let payload = EventsPayloadBuilder.build(eventAction: AccountEventAction.startOnboarding,
                                                       entityId: String(accountId)) else { return }
        let updateAccountOperation = APIOperation(EventsEndpoint.sendEvent(eventsPayload: payload))
        updateAccountOperation.execute(in: APIRequestDispatcher()) {_ in}
    }
}
