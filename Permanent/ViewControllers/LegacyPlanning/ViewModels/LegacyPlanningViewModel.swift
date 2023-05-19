//
//  LegacyPlanningViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 25.04.2023.
//

import Foundation

class LegacyPlanningViewModel: ViewModelInterface {
    static let didUpdateSelectedSteward = NSNotification.Name("LegacyPlanningViewModel.didUpdateSelectedSteward")
    var selectedArchive: ArchiveVOData?
    var selectedSteward: LegacyPlanningSteward?
    var stewardType: LegacyPlanningSteward.StewardType?
    
    func addSelectedSteward(name: String, email: String, status: LegacyPlanningSteward.StewardStatus) {
        selectedSteward = LegacyPlanningSteward(name: name, email: email, status: status, type: stewardType ?? .archive)
        
        NotificationCenter.default.post(name: Self.didUpdateSelectedSteward, object: self, userInfo: nil)
    }
    
    func deleteSelectedSteward() {
        selectedSteward = nil
        
        NotificationCenter.default.post(name: Self.didUpdateSelectedSteward, object: self, userInfo: nil)
    }
    
    func getLegacyPlanningAccount() -> Bool {
        return false
    }
}
