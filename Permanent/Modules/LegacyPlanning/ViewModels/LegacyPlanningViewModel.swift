//
//  LegacyPlanningViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 25.04.2023.
//

import Foundation

class LegacyPlanningViewModel: ViewModelInterface {
    var isLoading: ((Bool) -> Void)?
    var stewardWasUpdated: ((Bool) -> Void)?
    var showError: ((APIError) -> Void)?
    var stewardWasSaved: ((Bool) -> Void)?
    
    var selectedArchive: ArchiveVOData?
    var selectedSteward: LegacyPlanningSteward?
    var account: AccountVOData?
    var stewardType: LegacyPlanningSteward.StewardType?
    
    let legacyPlanningRepository: LegacyPlanningRepository
    
    init(legacyPlanningRepository: LegacyPlanningRepository = LegacyPlanningRepository()) {
        self.legacyPlanningRepository = legacyPlanningRepository
    }
    
    func addSteward(name: String, email: String, note: String = "", status: LegacyPlanningSteward.StewardStatus = .pending) {
        if stewardType == .archive {
            addArchiveSteward(name: name, email: email, note: note, status: status)
        } else {
            addAccountSteward(name: name, email: email)
        }
    }
    
    func getSteward() {
        if stewardType == .archive {
            getArchiveSteward()
        } else {
            getAccountSteward()
        }
    }
    
    func updateTrustedSteward(name: String?, stewardEmail: String?, note: String = "") {
        if stewardType == .archive {
            updateArchiveSteward(name: name ?? "", email: stewardEmail ?? "", note: note, status: .pending)
        } else {
            updateAccountSteward(name: name, stewardEmail: stewardEmail)
        }
    }
    
    func addArchiveSteward(name: String, email: String, note: String, status: LegacyPlanningSteward.StewardStatus) {
        isLoading?(true)
        legacyPlanningRepository.setArchiveSteward(archiveId: selectedArchive?.archiveID ?? 0, stewardEmail: email, note: note) { [weak self] result in
            switch result {
            case .failure(let error):
                if let error = error as? APIError {
                    self?.showError?(error)
                }
            case .success(let steward):
                self?.selectedSteward = LegacyPlanningSteward(id: steward.directiveId, name: name, email: email, status: .pending, type: .archive)
                self?.stewardWasUpdated?(true)
                self?.trackUpdateEvents(action: DirectiveEventAction.create, entityId: steward.directiveId)
            }
            
            self?.isLoading?(false)
        }
    }
    
    func addAccountSteward(name: String, email: String) {
        isLoading?(true)
        legacyPlanningRepository.setAccountSteward(name: name, stewardEmail: email) { [weak self] result in
            switch result {
            case .failure(let error):
                if let error = error as? APIError {
                    self?.showError?(error)
                }
            case .success(let steward):
                self?.selectedSteward = LegacyPlanningSteward(id: steward.legacyContactId, name: steward.name, email: steward.email, status: .pending, type: .account)
                self?.stewardWasUpdated?(true)
                self?.trackUpdateEvents(action: LegacyContactEventAction.create, entityId: self?.selectedSteward?.id)
            }
            
            self?.isLoading?(false)
        }
    }
    
    func getArchiveSteward() {
        guard let archiveId = selectedArchive?.archiveID else { return }
        isLoading?(true)
        legacyPlanningRepository.getArchiveSteward(archiveId: archiveId) { [weak self] result in
            switch result {
            case .failure(let error):
                if let error = error as? APIError {
                    switch error {
                    case .noData:
                        self?.selectedSteward = nil
                        self?.stewardWasUpdated?(true)
                        break
                    default:
                        self?.showError?(error)
                    }
                }
                self?.isLoading?(false)
            case .success(let response):
                guard let steward = response?.first else {
                    self?.selectedSteward = nil
                    self?.stewardWasUpdated?(true)
                    
                    self?.isLoading?(false)
                    return
                }
                
                self?.selectedSteward = LegacyPlanningSteward(id: steward.directiveId, name: steward.steward?.name ?? "", email: steward.steward?.email ?? "", note: steward.note, status: .pending, type: .archive)
                self?.isLoading?(false)
                self?.stewardWasUpdated?(true)
            }
        }
    }
    
    func getAccountSteward() {
        isLoading?(true)
        getLegacyPlanningAccount { [weak self] result in
            self?.isLoading?(false)
            switch result {
            case .success(_):
                self?.stewardWasUpdated?(true)
            case .failure(let error):
                self?.showError?(error)
            }
            
            self?.isLoading?(false)
        }
    }
    
    func getLegacyPlanningAccount(completion: @escaping (Result<Bool?, APIError>) -> Void) {
        legacyPlanningRepository.getLegacyContact { [weak self] result in
            switch result {
            case .failure(let error):
                completion(.failure(error as? APIError ?? .invalidResponse))
            case .success(let contact):
                if let name = contact?.first?.name, let email = contact?.first?.email, let legacyContactId = contact?.first?.legacyContactId {
                    self?.selectedSteward = LegacyPlanningSteward(id: legacyContactId, name: name, email: email, status: .pending, type: .account)
                } else {
                    self?.selectedSteward = nil
                }
                completion(.success(contact?.first?.name != nil))
            }
        }
    }
    
    func updateArchiveSteward(name: String, email: String, note: String, status: LegacyPlanningSteward.StewardStatus) {
        isLoading?(true)
        guard let id = selectedSteward?.id else {
            isLoading?(false)
            return
        }
        legacyPlanningRepository.updateArchiveSteward(directiveId: id, stewardEmail: email, note: note) { [weak self] result in
            switch result {
            case .failure(let error):
                if let error = error as? APIError {
                    self?.showError?(error)
                }
            case .success(let steward):
                self?.trackUpdateEvents(action: DirectiveEventAction.update, entityId: steward.directiveId)
                self?.selectedSteward = LegacyPlanningSteward(id: steward.directiveId, name: name, email: email, status: .pending, type: .archive)
                self?.stewardWasUpdated?(true)
            }
            
            self?.isLoading?(false)
        }
    }
    
    func updateAccountSteward(name: String?, stewardEmail: String?) {
        isLoading?(true)
        legacyPlanningRepository.updateAccountSteward(legacyContactId: selectedSteward?.id ?? "", name: name, stewardEmail: stewardEmail) { [weak self] result in
            switch result {
            case .failure(let error):
                if let error = error as? APIError {
                    self?.showError?(error)
                }
            case .success:
                self?.trackUpdateEvents(action: LegacyContactEventAction.update, entityId: self?.selectedSteward?.id)
                self?.selectedSteward = LegacyPlanningSteward(id: self?.selectedSteward?.id ?? "", name: name ?? "", email: stewardEmail ?? "", status: .pending, type: .account)
                self?.stewardWasUpdated?(true)
            }
            
            self?.isLoading?(false)
        }
    }
    
    func trackEvents(action: AccountEventAction) {
        guard let accountId = account?.accountID,
              let payload = EventsPayloadBuilder.build(accountId: accountId,
                                                       eventAction: action,
                                                       entityId: String(accountId)) else { return }
        let updateAccountOperation = APIOperation(EventsEndpoint.sendEvent(eventsPayload: payload))
        updateAccountOperation.execute(in: APIRequestDispatcher()) {_ in}
    }
    
    func trackUpdateEvents(action: any EventAction, entityId: String?) {
        guard let accountId = account?.accountID,
              let payload = EventsPayloadBuilder.build(accountId: accountId,
                                                       eventAction: action,
                                                       entityId: entityId) else { return }
        let updateAccountOperation = APIOperation(EventsEndpoint.sendEvent(eventsPayload: payload))
        updateAccountOperation.execute(in: APIRequestDispatcher()) {_ in}
    }
}


