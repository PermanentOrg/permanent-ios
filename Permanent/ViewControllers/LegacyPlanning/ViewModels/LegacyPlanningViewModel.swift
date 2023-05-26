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
    
    func addArchiveSteward(name: String, email: String, note: String, status: LegacyPlanningSteward.StewardStatus) {
        isLoading?(true)
        legacyPlanningRepository.setArchiveSteward(archiveId: selectedArchive?.archiveID ?? 0, stewardEmail: email, note: note) { [weak self] result in
            switch result {
            case .failure(let error):
                if let error = error as? APIError {
                    self?.showError?(error)
                }
            case .success:
                self?.selectedSteward = LegacyPlanningSteward(name: name, email: email, status: .pending, type: .archive)
                self?.stewardWasUpdated?(true)
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
            case .success:
                self?.selectedSteward = LegacyPlanningSteward(name: name, email: email, status: .pending, type: .account)
                self?.stewardWasUpdated?(true)
            }

            self?.isLoading?(false)
        }
    }
    
    func getSteward() {
        if stewardType == .archive {
            getArchiveSteward()
        } else {
            getAccountSteward()
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
                
                self?.selectedSteward = LegacyPlanningSteward(name: steward.steward?.name ?? "", email: steward.steward?.email ?? "", status: .pending, type: .archive)
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
        }
    }
    
    func getLegacyPlanningAccount(completion: @escaping (Result<Bool?, APIError>) -> Void) {
        legacyPlanningRepository.getLegacyContact { [weak self] result in
            switch result {
            case .failure(let error):
                completion(.failure(error as? APIError ?? .invalidResponse))
            case .success(let contact):
                if let name = contact?.first?.name, let email = contact?.first?.email {
                    self?.selectedSteward = LegacyPlanningSteward(name: name, email: email, status: .pending, type: .account)
                } else {
                    self?.selectedSteward = nil
                }
                completion(.success(contact?.first?.name != nil))
            }
        }
    }
    
}


