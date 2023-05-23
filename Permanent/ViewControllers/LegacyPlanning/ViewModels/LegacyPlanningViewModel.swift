//
//  LegacyPlanningViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 25.04.2023.
//

import Foundation

class LegacyPlanningViewModel: ViewModelInterface {
    static let didUpdateSelectedSteward = Notification.Name("LegacyPlanningViewModel.didUpdateSelectedSteward")
    static let getStewardAlert = Notification.Name("LegacyPlanningViewModel.getStewardAlert")

    var selectedArchive: ArchiveVOData?
    var selectedSteward: LegacyPlanningSteward?
    var stewardType: LegacyPlanningSteward.StewardType?
    
    let legacyPlanningRepository: LegacyPlanningRepository
    
    init(legacyPlanningRepository: LegacyPlanningRepository = LegacyPlanningRepository()) {
        self.legacyPlanningRepository = legacyPlanningRepository
    }
    
    func addSelectedSteward(name: String, email: String, note: String, status: LegacyPlanningSteward.StewardStatus, completion: @escaping (Result<Bool , Error>) -> Void) {
        legacyPlanningRepository.setArchiveSteward(archiveId: selectedArchive?.archiveID ?? 0, stewardEmail: email, note: note) { result, error in
            if result {
                self.selectedSteward = LegacyPlanningSteward(name: name, email: email, status: .pending, type: .archive)
                NotificationCenter.default.post(name: Self.didUpdateSelectedSteward, object: self, userInfo: nil)
                completion(.success(true))
            } else {
                if let error = error as? APIError {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func getCurrentSteward() {
        guard let archiveId = selectedArchive?.archiveID else { return }
        legacyPlanningRepository.getArchiveSteward(archiveId: archiveId) { response, error in
            guard let steward = response?.first else {
                if let error = error as? APIError {
                    switch error {
                    case .noData:
                        self.selectedSteward = nil
                        NotificationCenter.default.post(name: Self.didUpdateSelectedSteward, object: self, userInfo: nil)
                        break
                    default:
                        NotificationCenter.default.post(name: Self.getStewardAlert, object: self, userInfo: ["error": error])
                    }
                }
                return
            }
            self.selectedSteward = LegacyPlanningSteward(name: steward.stewardAccountId ?? "", email: steward.note ?? "", status: .pending, type: .archive)
            NotificationCenter.default.post(name: Self.didUpdateSelectedSteward, object: self, userInfo: nil)
        }
    }
    
    func getLegacyPlanningAccount() -> Bool {
        return false
    }
}
