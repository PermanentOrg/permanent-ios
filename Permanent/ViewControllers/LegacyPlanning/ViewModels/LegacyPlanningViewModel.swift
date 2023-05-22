//
//  LegacyPlanningViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 25.04.2023.
//

import Foundation

class LegacyPlanningViewModel: ViewModelInterface {
    static let didUpdateSelectedSteward = NSNotification.Name("LegacyPlanningViewModel.didUpdateSelectedSteward")
    static let isLoadingNotification = Notification.Name("LegacyPlanningViewModel.isLoadingNotification")
    
    var isLoading: Bool = false {
        didSet {
            NotificationCenter.default.post(name: Self.isLoadingNotification, object: self, userInfo: nil)
        }
    }

    var selectedArchive: ArchiveVOData?
    var selectedSteward: LegacyPlanningSteward?
    var stewardType: LegacyPlanningSteward.StewardType?
    
    let legacyPlanningRepository: LegacyPlanningRepository
    
    init(legacyPlanningRepository: LegacyPlanningRepository = LegacyPlanningRepository()) {
        self.legacyPlanningRepository = legacyPlanningRepository
    }
    
    func addSelectedSteward(name: String, email: String, status: LegacyPlanningSteward.StewardStatus) {
        isLoading = true
        legacyPlanningRepository.setArchiveSteward(archiveId: selectedArchive?.archiveID ?? 0, stewardEmail: email, note: "") { result, error in
            self.isLoading = false
            if result {
                self.getCurrentSteward()
            }
        }
    }
    
    func getCurrentSteward() {
        isLoading = true
        guard let archiveId = selectedArchive?.archiveID else { return }
        legacyPlanningRepository.getArchiveSteward(archiveId: archiveId) { response, error in
            self.isLoading = false
            if let steward = response?.first {
                self.selectedSteward?.name = steward.stewardAccountId ?? ""
                self.selectedSteward?.email = steward.note ?? ""
                NotificationCenter.default.post(name: Self.didUpdateSelectedSteward, object: self, userInfo: nil)}
        }
    }
    
    func getLegacyPlanningAccount() -> Bool {
        return false
    }
}
