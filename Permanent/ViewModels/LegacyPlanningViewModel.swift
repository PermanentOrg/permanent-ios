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
    var selectedSteward: ArchiveSteward?
    
    let legacyPlanningRepository: LegacyPlanningRepository
    
    init(legacyPlanningRepository: LegacyPlanningRepository = LegacyPlanningRepository()) {
        self.legacyPlanningRepository = legacyPlanningRepository
    }
    
    func isValidEmail(email: String?) -> Bool {
        guard let email = email else { return false }
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    func addSelectedSteward(name: String, email: String, status: ArchiveSteward.StewardStatus) {
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
            if let response = response {
                self.selectedSteward?.name = response.stewardAccountId ?? ""
                self.selectedSteward?.email = response.note ?? ""
                NotificationCenter.default.post(name: Self.didUpdateSelectedSteward, object: self, userInfo: nil)}
        }
    }
    
    func deleteSelectedSteward() {
        selectedSteward = nil
        
        NotificationCenter.default.post(name: Self.didUpdateSelectedSteward, object: self, userInfo: nil)
    }
}
