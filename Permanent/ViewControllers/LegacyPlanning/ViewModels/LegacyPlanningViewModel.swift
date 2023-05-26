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
    var stewardType: LegacyPlanningSteward.StewardType?
    
    let legacyPlanningRepository: LegacyPlanningRepository
    
    init(legacyPlanningRepository: LegacyPlanningRepository = LegacyPlanningRepository()) {
        self.legacyPlanningRepository = legacyPlanningRepository
    }
    
    func addSelectedSteward(name: String, email: String, note: String, status: LegacyPlanningSteward.StewardStatus) {
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
            }

            self?.isLoading?(false)
        }
    }
    
    func getCurrentSteward() {
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
                
                self?.selectedSteward = LegacyPlanningSteward(id: steward.directiveId, name: steward.steward?.name ?? "", email: steward.steward?.email ?? "", status: .pending, type: .archive)
                self?.isLoading?(false)
                self?.stewardWasUpdated?(true)
            }
        }
    }
    
    func updateSelectedSteward(name: String, email: String, note: String, status: LegacyPlanningSteward.StewardStatus) {
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
                self?.selectedSteward = LegacyPlanningSteward(id: steward.directiveId, name: name, email: email, status: .pending, type: .archive)
                self?.stewardWasUpdated?(true)
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
                completion(.success(contact?.first?.name != nil))
            }
        }
    }

}


