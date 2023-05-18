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
    
    func isValidEmail(email: String?) -> Bool {
        guard let email = email else { return false }
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
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
